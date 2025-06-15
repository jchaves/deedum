import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themesProvider = StateNotifierProvider<ThemesProvider, ThemeMode?>((_)  {
  return ThemesProvider();
});


class ThemesProvider extends StateNotifier<ThemeMode?>{
  ThemesProvider() : super(ThemeMode.system);

  void changeTheme(int mode) {
      switch(mode){
        case 0:
          state = ThemeMode.system;
          break;
        case 1:
          state = ThemeMode.light;
          break;
        case 2:
          state = ThemeMode.dark;
          break;
      }

    }

}