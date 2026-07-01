import 'package:flutter/material.dart';

import '../config/branding_config.dart';
import '../layout/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/rf_village_gradient.dart';

enum RfVillageLogoSize { appBar, hero }

class RfVillageLogo extends StatelessWidget {
  const RfVillageLogo({required this.size, super.key});

  final RfVillageLogoSize size;

  static const _fullAssetPath = BrandingConfig.heroLogoAsset;
  static const _iconAssetPath = BrandingConfig.appBarIconAsset;

  double _heroHeight(BuildContext context) {
    final isNarrow =
        MediaQuery.sizeOf(context).width < AppBreakpoints.narrow;
    return isNarrow ? 104 : 132;
  }

  double _appBarHeight(BuildContext context) {
    final isNarrow =
        MediaQuery.sizeOf(context).width < AppBreakpoints.narrow;
    return isNarrow ? 36 : 40;
  }

  Widget _buildImage({
    required String assetPath,
    required double? width,
    required double? height,
    FilterQuality filterQuality = FilterQuality.none,
    bool isAntiAlias = false,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: filterQuality,
      isAntiAlias: isAntiAlias,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (size == RfVillageLogoSize.appBar) {
      final iconSize = _appBarHeight(context);
      return _buildImage(
        assetPath: _iconAssetPath,
        width: iconSize,
        height: iconSize,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      );
    }

    final image = _buildImage(
      assetPath: _fullAssetPath,
      width: null,
      height: _heroHeight(context),
    );

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: RfVillageGradient.cardAccent,
          boxShadow: [
            BoxShadow(
              color: AppColors.villageGreen.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppColors.villagePurple.withValues(alpha: 0.22),
              blurRadius: 36,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.villagePanel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: image,
        ),
      ),
    );
  }
}
