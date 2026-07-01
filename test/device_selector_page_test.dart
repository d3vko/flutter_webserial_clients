import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/core/config/device_profile.dart';
import 'package:lilygo_wardriving_web/core/theme/app_theme.dart';
import 'package:lilygo_wardriving_web/features/wardriving/presentation/device_selector_page.dart';

void main() {
  testWidgets(
    'DeviceSelectorPage renders all device cards without overflow on short viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 500));

      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DeviceSelectorPage()),
      );

      await tester.pumpAndSettle();

      for (final profile in DeviceProfile.all) {
        expect(find.text(profile.title), findsOneWidget);
      }

      expect(find.text('made by: d3v.k0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DeviceSelectorPage renders without overflow on narrow viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 500));

      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DeviceSelectorPage()),
      );

      await tester.pumpAndSettle();

      expect(find.text('made by: d3v.k0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
