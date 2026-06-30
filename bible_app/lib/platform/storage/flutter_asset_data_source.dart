import 'package:flutter/services.dart' show rootBundle;
import 'package:bible_core/data/repository.dart';

/// Flutter asset bundle implementation of DataSource
class FlutterAssetDataSource implements DataSource {
  @override
  Future<String> loadAsset(String path) async {
    return await rootBundle.loadString(path);
  }
  
  @override
  Future<bool> assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }
}
