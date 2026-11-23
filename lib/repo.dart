import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get sb => Supabase.instance.client;

typedef Rows = List<Map<String, dynamic>>;

class Repo {
  static final version = ValueNotifier<int>(0);
  static void bump() => version.value++;

  static Future<Rows> list(String table, {String order = 'created_at'}) async {
    final res = await sb.from(table).select().order(order, ascending: false);
    return Rows.from(res);
  }

  static Future<Rows> entries() async {
    final res = await sb
        .from('gato_entries')
        .select()
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false);
    return Rows.from(res);
  }

  static Future<void> save(String table, Map<String, dynamic> data,
      {String? id}) async {
    if (id == null) {
      await sb.from(table).insert(data);
    } else {
      await sb.from(table).update(data).eq('id', id);
    }
    bump();
  }

  static Future<void> remove(String table, String id) async {
    await sb.from(table).delete().eq('id', id);
    bump();
  }

  static Future<void> saveVoice(
      File file, int durationMs, List<int> markers, String title) async {
    final uid = sb.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await sb.storage.from('gato-voice').upload(path, file,
        fileOptions: const FileOptions(contentType: 'audio/mp4'));
    await sb.from('gato_voice_memos').insert({
      'title': title,
      'storage_path': path,
      'duration_ms': durationMs,
      'markers': markers,
    });
    bump();
  }

  static Future<String> voiceUrl(String path) =>
      sb.storage.from('gato-voice').createSignedUrl(path, 3600);

  static Future<void> removeVoice(Map<String, dynamic> m) async {
    await sb.storage.from('gato-voice').remove([m['storage_path'] as String]);
    await sb.from('gato_voice_memos').delete().eq('id', m['id'] as String);
    bump();
  }
}
