import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/actualizador_service.dart';

class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key});

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 24.0,
        bottom: 8.0,
      ),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _mostrarSelectorTipografia(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccione una tipografía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Inter (Moderna y legible)',
                style: TextStyle(fontFamily: 'Inter'),
              ),
              onTap: () {
                fuenteGlobalNotifier.value = 'Inter';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Quicksand (Amigable y redondeada)',
                style: TextStyle(fontFamily: 'Quicksand'),
              ),
              onTap: () {
                fuenteGlobalNotifier.value = 'Quicksand';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Nunito (Equilibrada y versátil)',
                style: TextStyle(fontFamily: 'Nunito'),
              ),
              onTap: () {
                fuenteGlobalNotifier.value = 'Nunito';
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración General'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSeccionTitulo('PERSONALIZACIÓN'),
          ValueListenableBuilder<String>(
            valueListenable: fuenteGlobalNotifier,
            builder: (context, fuenteActual, child) {
              return ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: const Text('Tipografía de la aplicación'),
                subtitle: Text('Fuente activa: $fuenteActual'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _mostrarSelectorTipografia(context),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          // Envolvemos el Switch en un escuchador para que se actualice visualmente
          ValueListenableBuilder<ThemeMode>(
            valueListenable: temaGlobalNotifier,
            builder: (context, modoActual, child) {
              return SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Cambiar la apariencia de la aplicación.'),
                secondary: const Icon(Icons.dark_mode_outlined),
                // Ahora el valor depende de lo que dicte el escuchador
                value: modoActual == ThemeMode.dark,
                onChanged: (bool activado) async {
                  temaGlobalNotifier.value = activado
                      ? ThemeMode.dark
                      : ThemeMode.light;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('modo_oscuro', activado);
                },
              );
            },
          ),

          // SECCIÓN: SEGURIDAD
          _buildSeccionTitulo('SEGURIDAD'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Bloqueo de la aplicación'),
            subtitle: const Text('Proteger tus notas con PIN o huella'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Futura lógica de seguridad
              },
            ),
          ),

          // SECCIÓN: ALMACENAMIENTO
          _buildSeccionTitulo('ALMACENAMIENTO'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Copia de seguridad'),
            subtitle: const Text('Exportar o importar base de datos SQLite'),
            onTap: () {
              // Futura lógica de respaldo
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Limpiar datos de caché'),
            onTap: () {
              // Futura lógica de limpieza
            },
          ),

          // SECCIÓN: SOBRE LA APP
          _buildSeccionTitulo('SOBRE LA APP'),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('Buscar Actualizaciones'),
            subtitle: const Text(
              'Comprobar si hay una nueva version disponible',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ActualizadorService.verificarActualizacion(
                context,
                comprobacionManual: true,
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión de la aplicación'),
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
