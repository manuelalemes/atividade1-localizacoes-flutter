import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre o banco uma única vez e reutiliza a conexão.
/// Se a abertura falhar, a próxima chamada tenta novamente.
class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const String nomeBanco = 'localizacoes.db';
  static const String tabela = 'localizacoes';
  static const int versao = 1;

  Future<Database>? _conexao;

  Future<Database> get database async {
    try {
      return await (_conexao ??= _abrir());
    } catch (_) {
      _conexao = null; // permite nova tentativa
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      p.join(pasta, nomeBanco),
      version: versao,
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE $tabela (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
