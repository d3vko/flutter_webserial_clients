import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';
import 'package:lilygo_wardriving_web/features/wardriving/presentation/widgets/lte_data_table_source.dart';

void main() {
  test('LteDataTableSource maps row cells with Vue formatting', () {
    const record = LteRecord(
      timestamp: '2026-04-10T23:52:01.000Z',
      technology: 'LTE',
      cellType: '',
      status: '0',
      mcc: '334',
      mnc: '020',
      lac: '1201',
      cellId: '390112',
      eNodeB: '',
      sector: '',
      pci: '',
      band: '3',
      earfcn: '',
      freqDlMhz: '',
      freqUlMhz: '',
      rssi: '-73',
      rsrp: '-101',
      rsrq: '-10',
      sinr: '9',
      operator: '',
      longitude: '-99.1332090',
      latitude: '19.4326080',
      capturedAt: '2026-04-10T23:52:01.000Z',
    );

    final source = LteDataTableSource(rows: [record]);
    final row = source.getRow(0);
    expect(row, isNotNull);
    expect(row!.cells.length, 23);
    expect(
      (row.cells[0].child! as SelectableText).data,
      '2026-04-10T23:52:01.000Z',
    );
    expect((row.cells[2].child! as SelectableText).data, '—');
    expect((row.cells[19].child! as SelectableText).data, 'Unknown');
  });
}
