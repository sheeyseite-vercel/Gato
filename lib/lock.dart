import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Lock {
  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<bool> hasPin() async => (await _p).getString('pin_hash') != null;
  static Future<bool> skipped() async => (await _p).getBool('pin_skipped') ?? false;
  static Future<void> setSkipped(bool v) async => (await _p).setBool('pin_skipped', v);

  static String _hash(String salt, String pin) =>
      base64Encode(sha256.convert(utf8.encode('$salt:$pin')).bytes);

  static Future<void> setPin(String pin) async {
    final p = await _p;
    final r = Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
    await p.setString('pin_salt', salt);
    await p.setString('pin_hash', _hash(salt, pin));
    await p.setBool('pin_skipped', false);
  }

  static Future<bool> verify(String pin) async {
    final p = await _p;
    final salt = p.getString('pin_salt');
    final h = p.getString('pin_hash');
    if (salt == null || h == null) return false;
    return _hash(salt, pin) == h;
  }

  static Future<void> clear() async {
    final p = await _p;
    await p.remove('pin_hash');
    await p.remove('pin_salt');
  }

  static Future<int> autoLockSeconds() async => (await _p).getInt('auto_lock') ?? 60;
  static Future<void> setAutoLock(int s) async => (await _p).setInt('auto_lock', s);
}
