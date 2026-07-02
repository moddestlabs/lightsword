import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:bible_core/data/repository.dart';

/// Flutter asset bundle implementation of DataSource
class FlutterAssetDataSource implements DataSource {
  @override
  Future<String> loadAsset(String path) async {
    try {
      print('FlutterAssetDataSource: Loading asset at path: $path');
      final result = await rootBundle.loadString(path);
      print('FlutterAssetDataSource: Successfully loaded ${result.length} bytes');
      return result;
    } catch (e) {
      print('FlutterAssetDataSource: ERROR loading $path: $e');
      rethrow;
    }
  }
  
  @override
  Future<Uint8List> loadBytes(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
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
