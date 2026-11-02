import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';

import '../../models/localizacao.dart';
import 'item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.cache,
    required this.onAtualizar,
  });

  /// Da mais recente (índice 0) para a mais antiga. Não pode ser vazia.
  final List<Localizacao> localizacoes;
  final CacheStore cache;
  final VoidCallback onAtualizar;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final MapController _controller = MapController();

  CameraFit _ajuste() {
    final pontos = widget.localizacoes
        .map((l) => LatLng(l.latitude, l.longitude))
        .toList();
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(pontos),
      padding: const EdgeInsets.all(48),
      maxZoom: 17,
    );
  }

  void _enquadrar() {
    if (widget.localizacoes.isEmpty) return;
    _controller.fitCamera(_ajuste());
  }

  @override
  void didUpdateWidget(covariant MapaLocalizacoes antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.localizacoes != widget.localizacoes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _mostrarDetalhes(Localizacao l) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(child: ItemLocalizacao(localizacao: l)),
    );
  }

  List<Marker> _marcadores() {
    final itens = widget.localizacoes;
    final marcadores = <Marker>[];
    // Do mais antigo ao mais recente, para o vermelho ficar por cima.
    for (var i = itens.length - 1; i >= 0; i--) {
      final l = itens[i];
      final recente = i == 0;
      marcadores.add(
        Marker(
          point: LatLng(l.latitude, l.longitude),
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _mostrarDetalhes(l),
            child: Icon(
              Icons.location_on,
              size: recente ? 44 : 32,
              color: recente ? Colors.red : Colors.blue,
            ),
          ),
        ),
      );
    }
    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCameraFit: _ajuste(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.edu.fatec.localizacoes',
              tileProvider: CachedTileProvider(store: widget.cache),
            ),
            MarkerLayer(markers: _marcadores()),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'enquadrar',
                tooltip: 'Enquadrar todos os pontos',
                onPressed: _enquadrar,
                child: const Icon(Icons.zoom_out_map),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'atualizar',
                tooltip: 'Atualizar registros',
                onPressed: widget.onAtualizar,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
