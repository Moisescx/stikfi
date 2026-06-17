import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../models/nota.dart';
import '../db/database_helper.dart';

class PantallaEdicion extends StatefulWidget {
  final Nota? nota;

  const PantallaEdicion({super.key, this.nota});

  @override
  State<PantallaEdicion> createState() => _PantallaEdicionState();
}

class _PantallaEdicionState extends State<PantallaEdicion> {
  final _tituloController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late quill.QuillController _quillController;

  final List<Color> _coloresPostIt = [
    const Color(0xFFFFE082),
    const Color(0xFFFFAB91),
    const Color(0xFFA5D6A7),
    const Color(0xFF81D4FA),
    const Color(0xFFCE93D8),
    const Color(0xFFF48FB1),
  ];

  late Color _colorSeleccionado;

  @override
  void initState() {
    super.initState();
    _colorSeleccionado = widget.nota != null
        ? Color(widget.nota!.colorFondo)
        : _coloresPostIt[0];

    if (widget.nota != null) {
      _tituloController.text = widget.nota!.titulo;

      try {
        final jsonDocument = jsonDecode(widget.nota!.contenido);
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(jsonDocument),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = quill.QuillController(
          document: quill.Document()..insert(0, widget.nota!.contenido),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = quill.QuillController.basic();
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _guardarNota() async {
    if (_tituloController.text.trim().isEmpty &&
        _quillController.document.isEmpty()) {
      Navigator.pop(context);
      return;
    }

    final contenidoJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    final notaGuardar = Nota(
      id: widget.nota?.id,
      titulo: _tituloController.text,
      contenido: contenidoJson,
      colorFondo: _colorSeleccionado.toARGB32(),
      fechaCreacion: widget.nota?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    if (widget.nota == null) {
      await _dbHelper.insertNota(notaGuardar.toMap());
    } else {
      await _dbHelper.updateNota(notaGuardar.toMap());
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _mostrarSelectorDeColor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 20.0,
            bottom: 40.0,
            left: 20.0,
            right: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Color de fondo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _coloresPostIt.map((color) {
                    final estaSeleccionado = _colorSeleccionado == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _colorSeleccionado = color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 15.0),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: estaSeleccionado
                                ? Colors.black54
                                : Colors.black12,
                            width: estaSeleccionado ? 3 : 1,
                          ),
                        ),
                        child: estaSeleccionado
                            ? const Icon(Icons.check, color: Colors.black54)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorSeleccionado,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: _mostrarSelectorDeColor,
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 30),
            onPressed: _guardarNota,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. El campo del Título permanece fijo arriba
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _tituloController,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Título de la nota...',
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // 2. El Editor ahora ocupa todo el espacio central de la nota
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: quill.QuillEditor.basic(
                controller: _quillController,
                config: const quill.QuillEditorConfig(
                  placeholder: 'Escribe tus ideas aquí...',
                ),
              ),
            ),
          ),

          // 3. La barra de herramientas al pie de la pantalla, ultra compacta
          SafeArea(
            child: Container(
              // Un fondo sutil semi-transparente para integrarse con el color del post-it
              color: Colors.black.withValues(alpha: 0.04),
              child: quill.QuillSimpleToolbar(
                controller: _quillController,
                config: const quill.QuillSimpleToolbarConfig(
                  // Desactivamos menús complejos para maximizar espacio
                  showFontFamily: false,
                  showFontSize: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showInlineCode: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showAlignmentButtons: false,
                  showHeaderStyle:
                      false, // Quita los formatos de encabezado H1, H2
                  showQuote: false,
                  showCodeBlock: false,
                  showLink: false,

                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showUndo: true,
                  showRedo: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
