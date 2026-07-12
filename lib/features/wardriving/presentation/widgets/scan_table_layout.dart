import 'dart:math' as math;

import '../../domain/models.dart';

const defaultHeadingRowHeight = 48.0;
const defaultDataRowHeight = 72.0;
const kPaginatedTableFooterHeight = 56.0;
const tableHeightSafetyPadding = 16.0;
const lteTableMinWidth = 2400.0;
const wifiTableMinWidth = 1700.0;
const bleTableMinWidth = 1700.0;

const radioTableColumns = [
  'MAC',
  'SSID',
  'AuthMode',
  'FirstSeen',
  'Channel',
  'RSSI',
  'Lat',
  'Long',
  'Altitude',
  'Accuracy',
  'Type',
  'Captured',
];

double tableMinWidthForScanType(ScanType type) => switch (type) {
  ScanType.lte => lteTableMinWidth,
  ScanType.wifi => wifiTableMinWidth,
  ScanType.ble => bleTableMinWidth,
};

double paginatedTableHeight({
  required int rowsPerPage,
  required int rowCount,
  double headingRowHeight = defaultHeadingRowHeight,
  double dataRowHeight = defaultDataRowHeight,
  double footerHeight = kPaginatedTableFooterHeight,
  double safetyPadding = tableHeightSafetyPadding,
}) {
  if (rowCount == 0) {
    return headingRowHeight + footerHeight;
  }

  final rowSlots = math.min(rowsPerPage, rowCount);
  final emptySlots = rowsPerPage - rowSlots;
  return headingRowHeight +
      rowSlots * dataRowHeight +
      emptySlots * dataRowHeight +
      footerHeight +
      safetyPadding;
}
