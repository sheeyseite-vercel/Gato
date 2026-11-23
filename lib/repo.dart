import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

typedef Rows = List<Map<String, dynamic>>;

/// Local storage: everything lives on this device (JSON file + voice files).
class Repo {
  static final version = ValueNotifier<int>(0);
  static void bump() => version.value++;

  static Map<String, List<Map<String, dynamic>>> _db = {};
  static late File _file;
  static late Directory _voiceDir;
  static late Directory _stickerDir;
  static Future<void> _chain = Future.value();

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/gato_data.json');
    _voiceDir = Directory('${dir.path}/voice');
    if (!await _voiceDir.exists()) await _voiceDir.create(recursive: true);
    _stickerDir = Directory('${dir.path}/stickers');
    if (!await _stickerDir.exists()) await _stickerDir.create(recursive: true);
    if (await _file.exists()) {
      try {
        final raw = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
        _db = raw.map((k, v) => MapEntry(
            k,
            List<Map<String, dynamic>>.from(
                (v as List).map((e) => Map<String, dynamic>.from(e as Map)))));
      } catch (_) {
        try {
          await _file.copy('${_file.path}.bak');
        } catch (_) {}
        _db = {};
      }
    }
  }

  static Future<void> _persist() {
    _chain = _chain.then((_) async {
      try {
        final tmp = File('${_file.path}.tmp');
        await tmp.writeAsString(jsonEncode(_db));
        await tmp.rename(_file.path);
      } catch (_) {}
    });
    return _chain;
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

  static Map<String, dynamic> _defaults(String table) {
    switch (table) {
      case 'gato_notes':
        return {'color': 'lime', 'pinned': false};
      case 'gato_quotes':
        return {'favorite': false, 'source': ''};
      default:
        return {};
    }
  }

  static Future<Rows> list(String table, {String order = 'created_at'}) async {
    final rows = (_db[table] ?? []).map((r) => Map<String, dynamic>.from(r)).toList();
    rows.sort((a, b) => '${b[order] ?? ''}'.compareTo('${a[order] ?? ''}'));
    return rows;
  }

  static Future<Rows> entries() async {
    final rows = (_db['gato_entries'] ?? []).map((r) => Map<String, dynamic>.from(r)).toList();
    rows.sort((a, b) {
      final c = '${b['entry_date'] ?? ''}'.compareTo('${a['entry_date'] ?? ''}');
      return c != 0 ? c : '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}');
    });
    return rows;
  }

  static Future<void> save(String table, Map<String, dynamic> data, {String? id}) async {
    final rows = _db.putIfAbsent(table, () => []);
    final now = DateTime.now().toUtc().toIso8601String();
    if (id == null) {
      rows.add({..._defaults(table), ...data, 'id': _newId(), 'created_at': now});
    } else {
      final i = rows.indexWhere((r) => r['id'] == id);
      if (i >= 0) rows[i] = {...rows[i], ...data};
    }
    await _persist();
    bump();
  }

  static Future<void> remove(String table, String id) async {
    _db[table]?.removeWhere((r) => r['id'] == id);
    await _persist();
    bump();
  }

  static Future<void> saveVoice(File file, int durationMs, List<int> markers, String title) async {
    final dest = '${_voiceDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await file.copy(dest);
    await save('gato_voice_memos', {
      'title': title,
      'storage_path': dest,
      'duration_ms': durationMs,
      'markers': markers,
    });
  }

  static Future<String> voiceUrl(String path) async => path;

  static Future<void> removeVoice(Map<String, dynamic> m) async {
    try {
      final f = File(m['storage_path'] as String);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await remove('gato_voice_memos', m['id'] as String);
  }

  static Future<String> saveSticker(String src) async {
    final dest = '${_stickerDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(src).copy(dest);
    return dest;
  }

  static Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// day (yyyy-MM-dd) -> mood id. Home picks override moods set inside entries.
  static Future<Map<String, String>> moodDays() async {
    final out = <String, String>{};
    final ents = await entries();
    for (final e in ents.reversed) {
      final m = e['mood'];
      if (m is String && m.isNotEmpty) out['${e['entry_date']}'] = m;
    }
    final logs = await list('gato_moods');
    for (final l in logs.reversed) {
      final m = l['mood'];
      if (m is String && m.isNotEmpty) out['${l['day']}'] = m;
    }
    return out;
  }

  static Future<void> setMood(String day, String mood) async {
    final rows = _db.putIfAbsent('gato_moods', () => []);
    final i = rows.indexWhere((r) => r['day'] == day);
    if (i >= 0) {
      rows[i] = {...rows[i], 'mood': mood};
    } else {
      rows.add({'id': _newId(), 'day': day, 'mood': mood, 'created_at': DateTime.now().toUtc().toIso8601String()});
    }
    await _persist();
    bump();
  }
}
