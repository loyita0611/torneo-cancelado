import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  // Necesario antes de usar servicios de plataforma (path_provider, audio, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de locale para DateFormat('es')
  await initializeDateFormatting('es', null);

  // Barra de estado: íconos claros sobre fondo oscuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: Color(0xFF0F0E17),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Orientación: permitir retrato y horizontal
  // (móvil/tablet pueden rotar)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    // ProviderScope: requerido por Riverpod. Envuelve TODA la app.
    const ProviderScope(child: TorneoApp()),
  );
}
