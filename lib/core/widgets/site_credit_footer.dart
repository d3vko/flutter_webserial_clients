import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SiteCreditFooter extends StatelessWidget {
  const SiteCreditFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'made by: d3v.k0',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.villageText.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
