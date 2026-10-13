import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persists a stable install-scoped device id for FCM registration.
class DeviceIdStore {
  const DeviceIdStore();

  static const String _key = 'fcm_device_id';
  static const Uuid _uuid = Uuid();

  Future<String> getOrCreate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString(_key)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String created = _uuid.v4();
    await prefs.setString(_key, created);
    return created;
  }
}
