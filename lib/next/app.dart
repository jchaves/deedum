// ignore: unused_import
import 'dart:developer';

import 'package:dumdeedum/models/app_state.dart';
import 'package:dumdeedum/browser_tab/menu.dart';
import 'package:dumdeedum/directory/bookmarks.dart';
import 'package:dumdeedum/directory/directory.dart';
import 'package:dumdeedum/directory/feeds.dart';
import 'package:dumdeedum/directory/history.dart';
import 'package:dumdeedum/directory/identities.dart';
import 'package:dumdeedum/directory/settings.dart';
import 'package:dumdeedum/directory/tabs.dart';
import 'package:dumdeedum/models/tab.dart';
import 'package:dumdeedum/next/address_bar.dart';
import 'package:dumdeedum/next/browser_tab.dart';
import 'package:dumdeedum/next/themes_provider.dart';
import 'package:flutter/material.dart' hide Tab;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' as foundation;


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool get isIos =>
    foundation.defaultTargetPlatform == foundation.TargetPlatform.iOS;

class Home extends ConsumerWidget {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppState appState = ref.watch(appStateProvider);
    var tabCount = appState.tabCount();
    var currentTab = appState.currentTabIndex()+1;
    if (_controller.text.isEmpty && appState.currentUri() != null) {
      _controller.text = appState.currentUri().toString();
    }
    Widget? bottomBar;
    if (isIos) {
      bottomBar = BottomAppBar(
          color: Theme.of(context).cardColor,
          child: ButtonBar(
            children: [
              TextButton(
                  onPressed: appState.canGoBack()
                      ? null
                      : () {
                          appState.handleBack();
                        },
                  child: const Icon(Icons.keyboard_arrow_left, size: 30)),
              TextButton(
                  onPressed: appState.canGoForward()
                      ? null
                      : () {
                          appState.handleForward();
                        },
                  child: const Icon(Icons.keyboard_arrow_right, size: 30))
            ],
            alignment: MainAxisAlignment.spaceBetween,
          ));
    }

    List<Widget> actions = [];
    actions = [
      // IconButton(
      //   icon: Icon(Icons.refresh),
      //     color: Colors.black,
      //     onPressed: () =>{
      //       appState.onLocation(appState.currentUri())
      //     }
      // ),
      IconButton(
        icon: SizedBox(
            // width: 23,
            height: 23,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(width: 2, color: Colors.black),
                    borderRadius: const BorderRadius.all(Radius.circular(3))),
                child: Align(
                    alignment: Alignment.center,
                    child: Text("$currentTab/$tabCount",
                        textScaleFactor: 1.15,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: "DejaVu Sans Mono",
                            fontSize: 13))))),
        onPressed: () =>
            {Navigator.pushNamed(navigatorKey.currentContext!, "/directory")},
      ),
      const TabMenuWidget(),
    ];
    return WillPopScope(
        onWillPop: () async {
          return appState.handleBack();
        },
        child: Scaffold(
          bottomNavigationBar: bottomBar,
          backgroundColor: (appState.hasError())
              ? Colors.deepOrange
              : Theme.of(context).canvasColor,
          appBar: AppBar(
              backgroundColor: Colors.orange,
              title: AddressBar(
                focusNode: _focusNode,
                controller: _controller,
              ),
              actions: actions),
          body: IndexedStack(index: appState.tabState.tabIndex, children: [
            for (final Tab t in appState.indexedTabs((p0, p1) => p1))
              BrowserTab(
                  key: ObjectKey(t.ident),
                  focusNode: _focusNode,
                  ident: t.ident,
                  scrollController: t.scrollController)
          ]),
        ));
  }
}

class App extends ConsumerWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppState appState = ref.watch(appStateProvider);
    final themeProvider = ref.watch(themesProvider);
    Future((){ref.read(themesProvider.notifier).changeTheme(int.parse(appState.settings["theme"]));});


    return MaterialApp(
        title: 'dumdeedum',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: "Source Serif Pro",
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: "Source Serif Pro",
          primarySwatch: Colors.grey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        themeMode: themeProvider,
        localizationsDelegates: const [
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => Home(),
          "/directory": (context) => const Directory(
                children: [
                  Tabs(),
                  Feeds(),
                  Bookmarks(),
                  History(),
                  Identities(),
                  Settings(),
                ],
                icons: [
                  Icons.tab,
                  Icons.rss_feed,
                  Icons.bookmark_border,
                  Icons.history,
                  Icons.person,
                  Icons.settings
                ],
              )
        });
  }
}
