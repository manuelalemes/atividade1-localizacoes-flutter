import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Prepara o cache em disco das imagens do mapa, em pasta privada do app.
class CacheMapa {
  static Future<CacheStore> abrir() async {
    final base = await getApplicationCacheDirectory();
    final pasta = Directory(p.join(base.path, 'tiles_mapa'));
    await pasta.create(recursive: true);
    return FileCacheStore(pasta.path);
  }
}
