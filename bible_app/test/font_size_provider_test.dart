import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_app/services/preferences_service.dart';
import 'package:bible_app/state/font_size_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.instance.initialize();
  });

  group('FontSizeProvider Tests', () {
    test('default font size and pinch zoom values', () async {
      final provider = FontSizeProvider();
      await provider.initialize();

      expect(provider.fontSize, 18.0);
      expect(provider.pinchToZoomEnabled, true);
    });

    test('setFontSize clamps values between min and max', () async {
      final provider = FontSizeProvider();
      await provider.initialize();

      await provider.setFontSize(8.0);
      expect(provider.fontSize, FontSizeProvider.minFontSize);

      await provider.setFontSize(50.0);
      expect(provider.fontSize, FontSizeProvider.maxFontSize);

      await provider.setFontSize(22.4);
      expect(provider.fontSize, 22.4);
    });

    test('setPinchToZoomEnabled updates setting', () async {
      final provider = FontSizeProvider();
      await provider.initialize();

      await provider.setPinchToZoomEnabled(false);
      expect(provider.pinchToZoomEnabled, false);

      await provider.setPinchToZoomEnabled(true);
      expect(provider.pinchToZoomEnabled, true);
    });

    test('ephemeral font size update and commit', () async {
      final provider = FontSizeProvider();
      await provider.initialize();

      provider.setFontSizeEphemeral(24.0);
      expect(provider.fontSize, 24.0);

      await provider.commitFontSize();
      expect(PreferencesService.instance.getFontSize(), 24.0);
    });

    test('setFontFamily updates and persists fontFamily setting', () async {
      final provider = FontSizeProvider();
      await provider.initialize();

      expect(provider.fontFamily, 'Cardo');

      await provider.setFontFamily('NotoSansHebrew');
      expect(provider.fontFamily, 'NotoSansHebrew');
      expect(PreferencesService.instance.getFontFamily(), 'NotoSansHebrew');

      final newProvider = FontSizeProvider();
      await newProvider.initialize();
      expect(newProvider.fontFamily, 'NotoSansHebrew');
    });
  });
}
