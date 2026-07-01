import 'package:go_router/go_router.dart';

import '../core/config/device_profile.dart';
import '../features/magspoof/presentation/magspoof_page.dart';
import '../features/marauder/presentation/marauder_page.dart';
import '../features/wardriving/presentation/device_selector_page.dart';
import '../features/wardriving/presentation/wardrive_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DeviceSelectorPage()),
    GoRoute(
      path: DeviceProfile.tsim7000g.routePath,
      builder: (context, state) =>
          const WardrivePage(profile: DeviceProfile.tsim7000g),
    ),
    GoRoute(
      path: DeviceProfile.tsim7600hg.routePath,
      builder: (context, state) =>
          const WardrivePage(profile: DeviceProfile.tsim7600hg),
    ),
    GoRoute(
      path: DeviceProfile.pwnterreyMarauder.routePath,
      builder: (context, state) =>
          const MarauderPage(profile: DeviceProfile.pwnterreyMarauder),
    ),
    GoRoute(
      path: DeviceProfile.magspoofV5.routePath,
      builder: (context, state) =>
          const MagspoofPage(profile: DeviceProfile.magspoofV5),
    ),
  ],
);
