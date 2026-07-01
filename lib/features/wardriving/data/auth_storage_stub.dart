import 'auth_storage.dart';

class StubAuthStorage implements AuthStorage {
  StoredAuth? _auth;

  @override
  Future<void> clear() async {
    _auth = null;
  }

  @override
  Future<StoredAuth?> load() async => _auth;

  @override
  Future<void> save(StoredAuth auth) async {
    _auth = auth;
  }
}

AuthStorage createAuthStorage() => StubAuthStorage();
