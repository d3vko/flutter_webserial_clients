class StoredAuth {
  const StoredAuth({
    required this.access,
    required this.refresh,
    required this.username,
  });

  final String access;
  final String refresh;
  final String username;

  Map<String, String> toJson() => {
    'access': access,
    'refresh': refresh,
    'username': username,
  };
}

abstract class AuthStorage {
  Future<StoredAuth?> load();
  Future<void> save(StoredAuth auth);
  Future<void> clear();
}

const authStorageKey = 'wardrive-auth';
