// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;

String? readLocalStorage(String key) => web.window.localStorage.getItem(key);

void writeLocalStorage(String key, String value) {
  web.window.localStorage.setItem(key, value);
}

bool prefersDarkScheme() =>
    web.window.matchMedia('(prefers-color-scheme: dark)').matches;
