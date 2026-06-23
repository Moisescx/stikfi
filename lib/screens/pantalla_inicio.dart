import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/nota.dart';
import 'pantalla_edicion.dart';
import 'pantalla_configuracion.dart';
import '../services/actualizador_service.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:share_plus/share_plus.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Nota> _notas = [];
  List<Nota> _notasFiltradas = [];
  bool _cargando = true;
  bool _estaBuscando = false;
  final _buscadorController = TextEditingController();

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

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _cargarNotas() async {
    setState(() => _cargando = true);

    try {
      final mapas = await _dbHelper.getNotas();
      _notas = mapas.map((map) => Nota.fromMap(map)).toList();

      // Aplicamos el filtro si el usuario estaba escribiendo algo
      if (_estaBuscando && _buscadorController.text.isNotEmpty) {
        final query = _buscadorController.text.toLowerCase();
        _notasFiltradas = _notas.where((nota) {
          final titulo = nota.titulo.toLowerCase();
          final contenido = _extraerTextoPlano(nota.contenido).toLowerCase();
          return titulo.contains(query) || contenido.contains(query);
        }).toList();
      } else {
        _notasFiltradas = _notas;
      }
    } catch (e) {
      debugPrint("Error al cargar notas desde SQLite: $e");
      _notas = [];
      _notasFiltradas = [];
    } finally {
      // Garantizamos que el estado de carga siempre termine, haya error o no
      setState(() => _cargando = false);
    }
  }

  void _filtrarNotas(String consulta) {
    setState(() {
      if (consulta.isEmpty) {
        _notasFiltradas = _notas;
      } else {
        _notasFiltradas = _notas.where((nota) {
          final titulo = nota.titulo.toLowerCase();
          final contenido = _extraerTextoPlano(nota.contenido).toLowerCase();
          final query = consulta.toLowerCase();

          return titulo.contains(query) || contenido.contains(query);
        }).toList();
      }
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
                leading: Icon(
                  nota.fijada ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                title: Text(nota.fijada ? 'Desfijar nota' : 'Fijar nota'),
                onTap: () async {
                  Navigator.pop(contextBottomSheet);

                  final notaActualizada = Nota(
                    id: nota.id,
                    titulo: nota.titulo,
                    contenido: nota.contenido,
                    colorFondo: nota.colorFondo,
                    fechaCreacion: nota.fechaCreacion,
                    fechaActualizacion: DateTime.now(),
                    fijada: !nota.fijada,
                  );

                  await _dbHelper.updateNota(notaActualizada.toMap());
                  _cargarNotas();
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _estaBuscando
            ? TextField(
                controller: _buscadorController,
                autofocus: true,
                style: TextStyle(
                  color: esOscuro ? Colors.white : Colors.black87,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar nota...',
                  hintStyle: TextStyle(
                    color: esOscuro ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: _filtrarNotas,
              )
            : const Text('Stikfi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_estaBuscando ? Icons.close : Icons.search),
            tooltip: _estaBuscando ? 'Cerrar Búsqueda' : 'Buscar',
            onPressed: () {
              setState(() {
                if (_estaBuscando) {
                  _estaBuscando = false;
                  _buscadorController.clear();
                  _notasFiltradas = _notas;
                } else {
                  _estaBuscando = true;
                }
              });
            },
          ),
          if (!_estaBuscando)
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
          : _notasFiltradas
                .isEmpty // <-- CORREGIDO: Ahora vigila la lista correcta
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _estaBuscando
                      ? 'No se encontraron notas que coincidan.'
                      : 'No hay notas aún. ¡Crea una!',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _notasFiltradas.length,
                itemBuilder: (context, index) {
                  final nota = _notasFiltradas[index];

                  Color colorFondoNota = Color(nota.colorFondo);
                  if (esOscuro) {
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
                    onLongPress: () => _mostrarMenuOpciones(nota),
                    borderRadius: BorderRadius.circular(8),
                    child: Card(
                      color: colorFondoNota,
                      elevation: esOscuro ? 2 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: nota.titulo.isNotEmpty
                                      ? Text(
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
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                if (nota.fijada)
                                  Icon(
                                    Icons.push_pin,
                                    size: 16,
                                    color: esOscuro
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                              ],
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
