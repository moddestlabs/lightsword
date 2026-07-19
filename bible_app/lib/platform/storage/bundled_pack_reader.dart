import 'package:bible_core/packs/pack_manifest.dart';
import 'package:bible_core/packs/pack_reader.dart';

import 'flutter_asset_data_source.dart';

/// Pack reader for data bundled with the Flutter app.
class BundledPackReader extends DataSourcePackReader {
  BundledPackReader()
      : super(
          dataSource: FlutterAssetDataSource(),
          packBasePaths: bundledPackBasePaths,
        );
}

const bundledPackBasePaths = {
  PackIds.maculaSyntax: 'packages/bible_core/assets/data/syntax',
  PackIds.strongsLexicon: 'packages/bible_core/assets/data/lexicon',
  PackIds.originalLanguageOt: 'packages/bible_core/assets/data/tahot',
  PackIds.originalLanguageNt: 'packages/bible_core/assets/data/greek',
};
