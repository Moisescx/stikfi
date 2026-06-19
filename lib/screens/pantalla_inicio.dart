import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/nota.dart';
import 'pantalla_edicion.dart';
import 'pantalla_configuracion.dart';
import '../services/actualizador_service.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:share_plus/share_plus.dart'; // Importación para compartir notas

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Nota> _notas = [];
  bool _cargando = true;

  String _extraerTextoPlano(String contenido) {
    try {
      if (contenido.trim().startsWith('[')) {
        final jsonDocument = jsonDecode(contenido);
        final documento = quill.Document.fromJson(jsonDocument);
        return documento.toPlainText().trim();
      }
      return contenido;
    } catch (e) {
      return contenido;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarNotas();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActualizadorService.verificarActualizacion(context);
    });
  }

  Future<void> _cargarNotas() async {
    setState(() => _cargando = true);
    final mapas = await _dbHelper.getNotas();
    setState(() {
      _notas = mapas.map((map) => Nota.fromMap(map)).toList();
      _cargando = false;
    });
  }

  Future<void> _abrirPantallaEdicion({Nota? nota}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PantallaEdicion(nota: nota)),
    );
    if (resultado == true) _cargarNotas();
  }

  Future<void> _confirmarEliminacion(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Nota?'),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _dbHelper.deleteNota(id);
      _cargarNotas();
    }
  }

  // Menú emergente al mantener presionada una nota
  void _mostrarMenuOpciones(Nota nota) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext contextBottomSheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Compartir nota'),
                onTap: () {
                  Navigator.pop(contextBottomSheet);
                  final textoLimpio = _extraerTextoPlano(nota.contenido);
                  final textoCompleto = nota.titulo.isNotEmpty
                      ? '${nota.titulo}\n\n$textoLimpio'
                      : textoLimpio;
                  SharePlus.instance.share(ShareParams(text: textoCompleto));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Eliminar nota',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(contextBottomSheet);
                  _confirmarEliminacion(nota.id!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos si el sistema está usando el modo oscuro actualmente
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stikfi'), // Actualizado con tu nombre oficial
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaConfiguracion(),
                ),
              );
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _notas.isEmpty
          ? const Center(child: Text('No hay notas aún. ¡Crea una!'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _notas.length,
                itemBuilder: (context, index) {
                  final nota = _notas[index];

                  // Lógica matemática para atenuar los colores brillantes en modo oscuro
                  Color colorFondoNota = Color(nota.colorFondo);
                  if (esOscuro) {
                    // Mezcla un 75% del color base oscuro de la app con un 25% del color del post-it
                    colorFondoNota =
                        Color.lerp(
                          colorFondoNota,
                          const Color(0xFF2D2D2D),
                          0.75,
                        ) ??
                        colorFondoNota;
                  }

                  return InkWell(
                    onTap: () => _abrirPantallaEdicion(nota: nota),
                    onLongPress: () => _mostrarMenuOpciones(
                      nota,
                    ), // Cambiado por el menú modular
                    borderRadius: BorderRadius.circular(8),
                    child: Card(
                      color:
                          colorFondoNota, // Aplicación del color inteligente calculado arriba
                      elevation: esOscuro
                          ? 2
                          : 4, // Menos sombra en modo oscuro para evitar ruidos visuales
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nota.titulo.isNotEmpty)
                              Text(
                                nota.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: esOscuro
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (nota.contenido.isNotEmpty)
                              const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                _extraerTextoPlano(nota.contenido),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: esOscuro
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirPantallaEdicion(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
