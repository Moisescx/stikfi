import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // Patrón Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bloc_notas.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        contenido TEXT,
        colorFondo INTEGER,
        fechaCreacion TEXT,
        fechaActualizacion TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
  }

  // Insertar una nota
  Future<int> insertNota(Map<String, dynamic> nota) async {
    final db = await database;
    return await db.insert('notas', nota);
  }

  // Obtener todas las notas
  Future<List<Map<String, dynamic>>> getNotas() async {
    final db = await database;
    return await db.query('notas', orderBy: 'fechaActualizacion DESC');
  }

  // Actualizar una nota
  Future<int> updateNota(Map<String, dynamic> nota) async {
    final db = await database;
    return await db.update(
      'notas',
      nota,
      where: 'id = ?',
      whereArgs: [nota['id']],
    );
  }

  // Eliminar una nota
  Future<int> deleteNota(int id) async {
    final db = await database;
    return await db.delete('notas', where: 'id = ?', whereArgs: [id]);
  }
}
