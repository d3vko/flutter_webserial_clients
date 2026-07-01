// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';

import 'package:web/web.dart' as web;

import 'auth_storage.dart';

class WebAuthStorage implements AuthStorage {
  @override
  Future<void> clear() async {
    web.window.localStorage.removeItem(authStorageKey);
  }

  @override
  Future<StoredAuth?> load() async {
    final stored = web.window.localStorage.getItem(authStorageKey);
    if (stored == null || stored.isEmpty) return null;

    try {
      final parsed = jsonDecode(stored) as Map<String, dynamic>;
      final access = parsed['access'] as String?;
      final refresh = parsed['refresh'] as String?;
      final username = parsed['username'] as String?;
      if (access == null || refresh == null || username == null) {
        return null;
      }
      return StoredAuth(access: access, refresh: refresh, username: username);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(StoredAuth auth) async {
    web.window.localStorage.setItem(authStorageKey, jsonEncode(auth.toJson()));
  }
}

AuthStorage createAuthStorage() => WebAuthStorage();
