import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final ServicoLocalizacao _servico = ServicoLocalizacao();
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();

  StreamSubscription<Position>? _assinatura;

  /// Encadeia as gravações para que nunca se sobreponham.
  Future<void> _filaGravacao = Future<void>.value();

  bool _iniciando = false;
  int _gravadas = 0;

  bool get _coletando => _assinatura != null;

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    if (_coletando || _iniciando) return;
    setState(() => _iniciando = true);

    try {
      final resultado = await _servico.verificarPermissoes();
      if (!mounted) return;

      if (resultado != ResultadoPermissao.concedida) {
        setState(() => _iniciando = false);
        await _orientar(resultado);
        return;
      }

      _assinatura = _servico.posicoes().listen(
            _aoReceberPosicao,
            onError: _aoOcorrerErro,
          );
      setState(() {
        _iniciando = false;
        _gravadas = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _iniciando = false);
      _mensagem('Não foi possível iniciar a coleta: $e');
    }
  }

  Future<void> _parar() async {
    final assinatura = _assinatura;
    if (assinatura == null) return;
    _assinatura = null;
    await assinatura.cancel();
    if (!mounted) return;
    setState(() {});
  }

  void _aoReceberPosicao(Position posicao) {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );
    _filaGravacao = _filaGravacao.then((_) async {
      try {
        await _repositorio.inserir(localizacao);
        if (mounted) setState(() => _gravadas++);
      } catch (e) {
        if (mounted) _mensagem('Erro ao salvar a posição: $e');
      }
    });
  }

  void _aoOcorrerErro(Object erro) {
    _parar();
    if (mounted) _mensagem('Erro na coleta de localização: $erro');
  }

  Future<void> _orientar(ResultadoPermissao resultado) async {
    final String texto;
    VoidCallback? acao;
    String? rotulo;

    switch (resultado) {
      case ResultadoPermissao.servicoDesativado:
        texto = 'O serviço de localização (GPS) está desativado. '
            'Ative-o para iniciar a coleta.';
        acao = _servico.abrirConfiguracoesLocalizacao;
        rotulo = 'Abrir configurações do GPS';
      case ResultadoPermissao.negada:
        texto = 'A permissão de localização é necessária para coletar '
            'as posições. Tente novamente e permita o acesso.';
      case ResultadoPermissao.negadaPermanentemente:
        texto = 'A permissão de localização foi negada permanentemente. '
            'Habilite-a nas configurações do aplicativo.';
        acao = _servico.abrirConfiguracoesApp;
        rotulo = 'Abrir configurações do app';
      case ResultadoPermissao.concedida:
        return;
    }

    await showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Localização'),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto),
            child: const Text('Fechar'),
          ),
          if (acao != null && rotulo != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(contexto);
                acao!();
              },
              child: Text(rotulo),
            ),
        ],
      ),
    );
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final podeIniciar = !_coletando && !_iniciando;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localização')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              _coletando ? Icons.gps_fixed : Icons.gps_off,
              size: 64,
              color: _coletando ? Colors.teal : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _coletando
                  ? 'Coleta ativa • $_gravadas posição(ões) gravada(s) '
                      'nesta sessão'
                  : 'Coleta parada',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: podeIniciar ? _iniciar : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _coletando ? _parar : null,
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  _abrir(TelaLocalizacoes(coletaAtiva: _coletando)),
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _abrir(const TelaMapa()),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _servico.abrirConfiguracoesApp,
              icon: const Icon(Icons.settings),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    );
  }
}
