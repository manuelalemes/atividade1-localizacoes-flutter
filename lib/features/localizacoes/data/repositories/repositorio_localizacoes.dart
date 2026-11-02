import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

class RepositorioLocalizacoes {
  RepositorioLocalizacoes({BancoLocalizacoes? banco})
      : _banco = banco ?? BancoLocalizacoes.instancia;

  final BancoLocalizacoes _banco;

  Future<int> inserir(Localizacao localizacao) async {
    final db = await _banco.database;
    return db.insert(BancoLocalizacoes.tabela, localizacao.toMap());
  }

  /// Retorna as últimas [limite] localizações, da mais recente à mais antiga.
  /// O limite vale apenas para a consulta; nada é apagado.
  Future<List<Localizacao>> consultarUltimas({int limite = 100}) async {
    final db = await _banco.database;
    final linhas = await db.query(
      BancoLocalizacoes.tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  /// Remove todas as linhas, preservando tabela e arquivo do banco.
  Future<int> excluirTodas() async {
    final db = await _banco.database;
    return db.delete(BancoLocalizacoes.tabela);
  }
}
