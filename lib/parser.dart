import 'dart:convert';
// ignore: unused_import
import 'dart:developer';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';

import 'package:dumdeedum/models/content_data.dart';

const allowMalformedUtf8Decoder = Utf8Decoder(allowMalformed: true);

void parseGopher(ContentData parsedData, Uint8List newBytes) {
  parsedData.bytesBuilder!.add(newBytes);

  parsedData.contentType = ContentType.text;
  if (parsedData.loadedUri?.pathSegments.last == 'gophermap' ||
      parsedData.loadedUri?.pathSegments.last == '/'
  ) {
    parsedData.mode = Modes.gophermap;
  }else{
    parsedData.mode = Modes.plain;
  }
  parsedData.upsertToByteStream(newBytes);

}

void parse(ContentData parsedData, Uint8List newBytes) {
  parsedData.bytesBuilder!.add(newBytes);

  if (parsedData.mode == Modes.loading) {
    int status;
    String? meta;
    int? prevChar;
    var endofline = 0;

    var bytes = parsedData.bytesBuilder!.toBytes();
    for (var byteIndex = 0; byteIndex < bytes.length; byteIndex++) {
      if (prevChar == 13 && bytes[byteIndex] == 10) {
        endofline = byteIndex;
        break;
      } else {
        prevChar = bytes[byteIndex];
      }
    }
    if (endofline == 0) {
      return;
    }

    var statusBytes = Uint8List.sublistView(bytes, 0, endofline - 1);
    if (statusBytes.isEmpty) {
      return;
    }

    var statusMeta = allowMalformedUtf8Decoder.convert(statusBytes);
    if (statusMeta.isEmpty) {
      return;
    }

    var m = RegExp(r'^(\d\d)\s(.+)$').firstMatch(statusMeta);
    if (m == null) {
      parsedData.mode = Modes.error;
      parsedData.static = "INVALID RESPONSE";
      return;
    }

    status = int.parse(m.group(1)!);
    meta = m.group(2);

    if (meta!.length > 1024) {
      parsedData.mode = Modes.error;
      parsedData.static = "META TOO LONG";
      return;
    }

    if (status < 10 || status >= 70) {
      parsedData.mode = Modes.error;
      parsedData.static = "UNHANDLED STATUS";
      return;
    }

    parsedData.status = status;
    parsedData.meta = meta;
    parsedData.bodyIndex = endofline + 1;
    if (status >= 10 && status < 20) {
      parsedData.mode = Modes.search;
    } else if (status >= 20 && status < 30) {
      parsedData.contentType = ContentType.parse(meta);

      if (parsedData.contentType!.mimeType == "text/gemini") {
        parsedData.mode = Modes.gem;
      } else if (parsedData.contentType!.mimeType.startsWith("text/")) {
        parsedData.mode = Modes.plain;
      } else if (parsedData.contentType!.mimeType.startsWith("image/")) {
        parsedData.mode = Modes.image;
      } else {
        parsedData.mode = Modes.binary;
      }
    } else if (status >= 30 && status < 40) {
      parsedData.mode = Modes.redirect;
    } else if (status >= 40 && status < 50) {
      parsedData.mode = Modes.error;
      parsedData.static = "Temporary Failure";
    } else if (status >= 50 && status < 60) {
      parsedData.mode = Modes.error;
      parsedData.static = "Permanent Failure";
    } else if (status >= 60 && status < 70) {
      parsedData.mode = Modes.clientCert;
    }
    if (bytes.length > endofline + 1) {
      newBytes = bytes.sublist(endofline + 1);
    } else {
      newBytes = Uint8List(0);
    }
  }
  if (parsedData.lineBased()) {
    parsedData.upsertToByteStream(newBytes);
  }
}

void addToGroup(r, String type, String line) {
  if (r["groups"].isNotEmpty && r["groups"].last["type"] == type) {
    var group = r["groups"].removeLast();
    (group["data"] as StringBuffer)
      ..write("\n")
      ..write(line);
    group["maxLine"] = math.max(line.length, (group["maxLine"] as int));
    r["groups"].add(group);
  } else {
    r["groups"].add(
        {"type": type, "data": StringBuffer(line), "maxLine": line.length});
  }
}

List<dynamic>? analyze(List<String> lines, {alwaysPre = false}) {
  var lineInfo = lines.fold({"groups": [], "parse?": true}, (dynamic r, line) {
    if (!alwaysPre && line.startsWith("```")) {
      r["parse?"] = !r["parse?"];
    } else if (alwaysPre || !r["parse?"]) {
      addToGroup(r, "pre", line);
    } else if (line.startsWith(">")) {
      addToGroup(r, "quote", line.substring(1));
    } else if (line.startsWith("#")) {
      var m = RegExp(r'^(#*)\s*(.*)$').firstMatch(line)!;
      var hashCount = math.min(m.group(1)!.length, 3);
      r["groups"].add({
        "type": "header",
        "data": StringBuffer(m.group(2)!),
        "size": hashCount
      });
    } else if (line.startsWith("=>")) {
      var m = RegExp(r'^=>\s*(\S+)\s*(.*)$').firstMatch(line);
      if (m != null) {
        var link = m.group(1);
        var rest = m.group(2)!.trim();
        var title = rest.isEmpty ? link : rest;
        r["groups"]
            .add({"type": "link", "link": link, "data": StringBuffer(title!)});
      }
    } else if (line.startsWith("* ")) {
      r["groups"]
          .add({"type": "list", "data": StringBuffer(line.substring(2))});
    } else {
      addToGroup(r, "line", line);
    }
    return r;
  });
  List? groups = lineInfo["groups"];
  return groups?.map((e) {
    e["data"] = e["data"].toString();
    return e;
  }).toList();
}


List<dynamic>? analyzeGopher(List<String> lines, {alwaysPre = false}) {
  var lineInfo = lines.fold({"groups": [], "parse?": true}, (dynamic r, line) {
    if (line.startsWith("i")) {
      var towrap= line.split('\t')[0].substring(1);
      addToGroup(r, "pre", towrap);
    } else if (line.startsWith("0") ||
        line.startsWith("1") ||
        line.startsWith("h") ) {

      var type=line[0];

        var parts = line.substring(1).split('\t');
        var link = "";
        if (parts.length == 4) {
          if(type == 'h'){
            // "URL:https://domain.whatever
            link = parts[1].substring(4);
          }else {
            //name, path, host, port
            link = "gopher://" + parts[2] + ':' + parts[3] + '/' + type + parts[1];
          }
          r["groups"]
              .add(
              {"type": "link", "link": link, "data": StringBuffer(parts[0])});
        } else {
          // kind of default, add as is
          addToGroup(r, "line", line);
        }

    }

    else{
      // kind of default, add as is
      addToGroup(r, "line", line);
    }
    return r;
  });
  List? groups = lineInfo["groups"];
  return groups?.map((e) {
    e["data"] = e["data"].toString();
    return e;
  }).toList();
}
