import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/core/config/device_profile.dart';
import 'package:lilygo_wardriving_web/core/theme/app_theme.dart';
import 'package:lilygo_wardriving_web/features/marauder/presentation/marauder_page.dart';
import 'package:lilygo_wardriving_web/features/wardriving/presentation/wardrive_page.dart';

void main() {
  testWidgets('MarauderPage shows Register when logged out', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const MarauderPage(profile: DeviceProfile.oficialMarauder),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Oficial Firmware'), findsOneWidget);
  });

  testWidgets('WardrivePage shows Register when logged out', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const WardrivePage(profile: DeviceProfile.tsim7000g),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
