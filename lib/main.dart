import 'package:flutter/material.dart';
import 'screens/pantalla_inicio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// Notificadores globales
final ValueNotifier<ThemeMode> temaGlobalNotifier = ValueNotifier(
  ThemeMode.light,
);
final ValueNotifier<String> fuenteGlobalNotifier = ValueNotifier<String>(
  'Inter',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final esOscuro = prefs.getBool('modo_oscuro') ?? false;
  temaGlobalNotifier.value = esOscuro ? ThemeMode.dark : ThemeMode.light;

  runApp(const BlockNotasApp());
}

class BlockNotasApp extends StatelessWidget {
  const BlockNotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: fuenteGlobalNotifier,
      builder: (context, fuente, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: temaGlobalNotifier,
          builder: (context, modoActual, child) {
            return MaterialApp(
              title: 'Stikfi',
              debugShowCheckedModeBanner: false,

              themeMode: modoActual,

              // CONFIGURACIÓN: TEMA CLARO
              theme: ThemeData(
                brightness: Brightness.light,
                useMaterial3: true,
                colorSchemeSeed: const Color(0xFFFFE082),
                textTheme: GoogleFonts.getTextTheme(fuente),
              ),

              darkTheme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                colorSchemeSeed: const Color(0xFFFFE082),
                scaffoldBackgroundColor: const Color(
                  0xFF1E1E1E,
                ), // Gris oscuro elegante
                // Le aplicamos la fuente y forzamos el texto a blanco
                textTheme: GoogleFonts.getTextTheme(
                  fuente,
                ).apply(bodyColor: Colors.white, displayColor: Colors.white),
              ),

              // Traducciones al español para el editor de texto
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FlutterQuillLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
              home: const PantallaInicio(),
            );
          },
        );
      },
    );
  }
}
