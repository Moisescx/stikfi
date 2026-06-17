import 'package:flutter/material.dart';
import 'screens/pantalla_inicio.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  runApp(const BlockNotasApp());
}

final ValueNotifier<String> fuenteGlobalNotifier = ValueNotifier<String>(
  'Inter',
);

class BlockNotasApp extends StatelessWidget {
  const BlockNotasApp({super.key});

  TextTheme _obtenerTextTheme(String nombreFuente) {
    switch (nombreFuente) {
      case 'Quicksand':
        return GoogleFonts.quicksandTextTheme();
      case 'Nunito':
        return GoogleFonts.nunitoTextTheme();
      case 'Inter':
      default:
        return GoogleFonts.interTextTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: fuenteGlobalNotifier,
      builder: (context, fuente, child) {
        return MaterialApp(
          title: 'Bloc de Notas Post-it',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFFFFE082),
            textTheme: _obtenerTextTheme(fuente),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale(
              'en'
              'US',
            ),
          ],
          home: const PantallaInicio(),
        );
      },
    );
  }
}
