import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/json_repository.dart';
import 'package:bible_app/platform/storage/flutter_asset_data_source.dart';

/// Global Bible repository instance
/// TODO: Replace with proper dependency injection / state management
class BibleService {
  static BibleRepository? _instance;
  
  static BibleRepository get instance {
    _instance ??= JsonBibleRepository(FlutterAssetDataSource());
    return _instance!;
  }
}
