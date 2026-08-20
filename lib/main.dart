import 'package:developer_workflow/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebaseSafely();

  await configureDependencies();

  runApp(const MyApp());
}

Future<void> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError catch (error) {
    debugPrint('[FIREBASE] Firebase no configurado para esta plataforma: $error');
  }
}
