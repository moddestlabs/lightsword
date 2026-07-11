import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/usfm_lazy_repository.dart';
import 'package:bible_app/platform/storage/flutter_asset_data_source.dart';
import 'package:bible_app/services/original_language_bible_repository.dart';
import 'package:bible_app/services/preferences_service.dart';

enum BibleTextSource {
  originalLanguage,
  bsb,
}

class BibleTextSourceOption {
  const BibleTextSourceOption({
    required this.source,
    required this.label,
    required this.description,
    required this.isTranslation,
  });

  final BibleTextSource source;
  final String label;
  final String description;
  final bool isTranslation;
}

/// Global Bible repository instance
/// TODO: Replace with proper dependency injection / state management
class BibleService {
  static final Map<BibleTextSource, BibleRepository> _repositories = {
    BibleTextSource.originalLanguage: OriginalLanguageBibleRepository(),
    BibleTextSource.bsb: UsfmLazyRepository(
      FlutterAssetDataSource(),
      'assets/data/usfm/bsb',
    ),
  };

  static const List<BibleTextSourceOption> availableSources = [
    BibleTextSourceOption(
      source: BibleTextSource.originalLanguage,
      label: 'Hebrew/Greek Glosses',
      description: 'Original language text with literal gloss-based reading.',
      isTranslation: false,
    ),
    BibleTextSourceOption(
      source: BibleTextSource.bsb,
      label: 'BSB Translation',
      description: 'Berean Standard Bible translation layer.',
      isTranslation: true,
    ),
  ];

  static BibleTextSource _currentSource = BibleTextSource.originalLanguage;

  static Future<void> initialize() async {
    final savedSourceId = PreferencesService.instance.getSelectedTextSource();
    _currentSource = _sourceFromId(savedSourceId);
  }

  static BibleRepository get instance {
    return _repositories[_currentSource]!;
  }

  static BibleTextSource get currentSource => _currentSource;

  static BibleTextSourceOption get currentSourceOption {
    return availableSources.firstWhere((option) => option.source == _currentSource);
  }

  static Future<void> setSource(BibleTextSource source) async {
    _currentSource = source;
    await PreferencesService.instance.setSelectedTextSource(_sourceId(source));
  }

  static String sourceLabel(BibleTextSource source) {
    return availableSources.firstWhere((option) => option.source == source).label;
  }

  static String _sourceId(BibleTextSource source) {
    switch (source) {
      case BibleTextSource.originalLanguage:
        return 'original_language';
      case BibleTextSource.bsb:
        return 'bsb';
    }
  }

  static BibleTextSource _sourceFromId(String? sourceId) {
    switch (sourceId) {
      case 'bsb':
        return BibleTextSource.bsb;
      case 'original_language':
      default:
        return BibleTextSource.originalLanguage;
    }
  }
}
