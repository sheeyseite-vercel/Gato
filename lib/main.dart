import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gate.dart';
import 'repo.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repo.init();
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
