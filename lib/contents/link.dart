// ignore: unused_import
import 'dart:developer';

import 'package:deedum/browser_tab/search.dart';
import 'package:deedum/models/app_state.dart';
import 'package:deedum/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Link extends ConsumerWidget {
  const Link({
    Key? key,
    required this.title,
    required this.link,
    required this.loadedUri,
  }) : super(key: key);

  final String link;
  final String title;
  final Uri loadedUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var appState = ref.watch(appStateProvider);
    Uri uri = resolveLink(loadedUri, link);
    bool httpWarn = uri.scheme != "gemini";
    bool visited = appState.recents.contains(uri.toString());
    return IgnorePointer(
        child: GestureDetector(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 7, 0, 7),
                child: Text((httpWarn ? "[${uri.scheme}] " : "") + title,
                    style: TextStyle(
                        color: httpWarn
                            ? (visited
                                ? Colors.purple[100]
                                : Colors.purple[300])
                            : (visited ? Colors.blueGrey : Colors.blue)))),
            onLongPress: () =>
                linkLongPressMenu(title, uri, appState.onNewTab, context),
            onTap: () {
              if(uri.scheme == "gopher" && uri.pathSegments.first == "7"){
                showSearchDialog(uri, context, appState);
              }else {
                appState.onLocation(uri);
              }
            }),
        ignoring: appState.currentLoading());
  }
}

Future<void> showSearchDialog(Uri uri, BuildContext context, AppState appState) async {
  var location = uri;
  var newLocation = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SearchAlert(prompt: "Type it!", uri: location);
      });
  if (newLocation != null) {
    appState.onLocation(newLocation);
  }
  return;
}

void linkLongPressMenu(title, uri, onNewTab, oldContext) =>
    showModalBottomSheet<void>(
        context: oldContext,
        builder: (BuildContext context) {
          return Container(
            constraints: BoxConstraints(
              minHeight: 50,
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            // color: Colors.amber,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(title: Center(child: Text(uri.toString()))),
                ListTile(
                  title: const Center(child: Text("Copy link")),
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: uri.toString()));
                    const snackBar =
                        SnackBar(content: Text('Copied to Clipboard'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Center(child: Text("Copy link text")),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: title));

                    const snackBar =
                        SnackBar(content: Text('Copied to Clipboard'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Center(child: Text("Open link in new tab")),
                  onTap: () {
                    Navigator.pop(context);
                    onNewTab(uri.toString());
                  },
                ),
              ],
            ),
          );
        });
