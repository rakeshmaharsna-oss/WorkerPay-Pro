import 'package:flutter/material.dart';
import 'app.dart';
import 'admob_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AdMobService.initialize();

  runApp(const WorkerPayApp());
}
