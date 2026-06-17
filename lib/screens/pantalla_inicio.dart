import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/nota.dart';
import 'pantalla_edicion.dart';
import 'pantalla_configuracion.dart';
import '../services/actualizador_service.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Nota> _notas = [];
  bool _cargando = true;

  // Función para convertir el código JSON a texto normal para la previsualización
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

  // Lee las notas desde la base de datos y actualiza la UI
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
    if (resultado == true) _cargarNotas(); // Recarga si se guardó o editó
  }

  Future<void> _confirmarEliminacion(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Nota?'),
        content: const Text(
          'Esta accion no se puede deshacer. ¿Deseas continuar?',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Post-its'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuracion',
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
                  crossAxisCount: 2, // Dos columnas tipo tablero
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _notas.length,
                itemBuilder: (context, index) {
                  final nota = _notas[index];
                  return InkWell(
                    onTap: () => _abrirPantallaEdicion(nota: nota),
                    onLongPress: () => _confirmarEliminacion(nota.id!),
                    borderRadius: BorderRadius.circular(8),
                    child: Card(
                      color: Color(nota.colorFondo),
                      elevation: 4,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (nota.contenido.isNotEmpty)
                              const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                _extraerTextoPlano(nota.contenido),
                                style: const TextStyle(fontSize: 14),
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
