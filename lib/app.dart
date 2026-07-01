import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'core/theme/app_theme.dart';

class LilygoWardrivingApp extends StatelessWidget {
  const LilygoWardrivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RF Village MX Serial Clients',
      theme: AppTheme.dark(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
