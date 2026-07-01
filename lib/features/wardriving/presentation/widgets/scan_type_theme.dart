import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models.dart';
import 'scan_table_layout.dart';

class ScanTypeTheme {
  const ScanTypeTheme({
    required this.scanType,
    required this.accent,
    required this.tableMinWidth,
  });

  final ScanType scanType;
  final Color accent;
  final double tableMinWidth;

  factory ScanTypeTheme.forType(ScanType type) => switch (type) {
    ScanType.lte => const ScanTypeTheme(
      scanType: ScanType.lte,
      accent: AppColors.villageGreen,
      tableMinWidth: lteTableMinWidth,
    ),
    ScanType.wifi => const ScanTypeTheme(
      scanType: ScanType.wifi,
      accent: AppColors.villagePurple,
      tableMinWidth: wifiTableMinWidth,
    ),
    ScanType.ble => const ScanTypeTheme(
      scanType: ScanType.ble,
      accent: AppColors.villageCyan,
      tableMinWidth: bleTableMinWidth,
    ),
  };

  DataColumn column(String label) => DataColumn(
    label: Text(
      label,
      style: TextStyle(
        color: accent,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  );

  List<DataColumn> columnsFor(List<String> labels) =>
      labels.map(column).toList();

  Color? zebraForRow(int index) =>
      index.isOdd ? accent.withValues(alpha: 0.06) : null;

  Color signalStrengthColor(String raw, {bool higherIsBetter = false}) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return AppColors.villageText;

    if (higherIsBetter) {
      if (parsed >= 10) return AppColors.villageGreen;
      if (parsed >= 3) return AppColors.warningAmber;
      return AppColors.errorRed;
    }

    if (parsed >= -70) return AppColors.villageGreen;
    if (parsed >= -85) return AppColors.warningAmber;
    return AppColors.errorRed;
  }
}
