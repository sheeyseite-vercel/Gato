import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.supabaseKey);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.deep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const GatoApp());
}

class GatoApp extends StatelessWidget {
  const GatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GATO',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Gate(),
    );
  }
}
