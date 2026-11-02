import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  final bool coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _itens = const [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await _repositorio.consultarUltimas(limite: 100);
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao consultar o histórico: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _limpar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Limpar histórico'),
        content: Text(
          'Todos os registros serão excluídos, inclusive os anteriores aos '
          '100 exibidos. Esta operação é permanente.'
          '${widget.coletaAtiva ? '\n\nA coleta está ativa: novos registros '
              'continuarão sendo salvos.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    try {
      await _repositorio.excluirTodas();
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      _mensagem('Histórico apagado com sucesso.');
    } catch (e) {
      if (!mounted) return;
      _mensagem('Falha ao apagar o histórico: $e');
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar todo o histórico',
            onPressed: _limpar,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando && _itens.isEmpty && _erro == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final Widget conteudo;
    if (_erro != null) {
      conteudo = ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_erro!, textAlign: TextAlign.center),
          ),
        ],
      );
    } else if (_itens.isEmpty) {
      conteudo = ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nenhuma localização registrada.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else {
      conteudo = ListView.separated(
        itemCount: _itens.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => ItemLocalizacao(localizacao: _itens[i]),
      );
    }
    return RefreshIndicator(onRefresh: _carregar, child: conteudo);
  }
}
