import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ActualizadorService {
  static const String _urlJsonRemoto =
      'https://raw.githubusercontent.com/Moisescx/stikfi/refs/heads/main/version.json';

  static Future<void> verificarActualizacion(BuildContext context) async {
    try {
      final infoPaquete = await PackageInfo.fromPlatform();
      final int versionCodeLocal = int.parse(infoPaquete.buildNumber);

      final respuesta = await http.get(Uri.parse(_urlJsonRemoto));
      if (respuesta.statusCode != 200) return;

      final Map<String, dynamic> datosRemotos = jsonDecode(respuesta.body);
      final int versionCodeRemoto = datosRemotos['version_code'];
      final String versionNameRemoto = datosRemotos['version_name'];
      final String urlApk = datosRemotos['url_apk'];
      final List<dynamic> listaCambios = datosRemotos['cambios'];

      if (versionCodeRemoto > versionCodeLocal) {
        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                '¡Nueva versión disponible (v$versionNameRemoto)!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Novedades de esta actualización:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...listaCambios.map(
                    (cambio) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(child: Text(cambio.toString())),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Más tarde',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () async {
                    final Uri url = Uri.parse(urlApk);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text('Actualizar ahora'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error al verificar actualización: $e');
    }
  }
}
