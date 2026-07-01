import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class RfVillageGradient {
  static const header = LinearGradient(
    colors: [
      AppColors.villagePurpleDarker,
      AppColors.villagePurple,
      AppColors.villageCyan,
      AppColors.villageGreen,
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const cardAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.villagePurple, AppColors.villageGreen],
  );
}
