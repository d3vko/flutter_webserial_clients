import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilygo_wardriving_web/features/wardriving/domain/models.dart';
import 'package:lilygo_wardriving_web/features/wardriving/presentation/widgets/scan_data_section.dart';

const _sampleLteRecord = LteRecord(
  timestamp: '',
  technology: 'LTE',
  cellType: 'FDD-LTE',
  status: '0',
  mcc: '334',
  mnc: '020',
  lac: '1201',
  cellId: '390112',
  eNodeB: '6095',
  sector: '2',
  pci: '123',
  band: '3',
  earfcn: '1300',
  freqDlMhz: '2115.0',
  freqUlMhz: '1920.0',
  rssi: '-73',
  rsrp: '-101',
  rsrq: '-10',
  sinr: '9',
  operator: 'Telcel',
  longitude: '-99.1332090',
  latitude: '19.4326080',
  capturedAt: '2026-04-10T23:52:01.000Z',
);

void main() {
  testWidgets(
    'ScanDataSection renders LTE table with two rows without overflow',
    (tester) async {
      const rows = [
        _sampleLteRecord,
        LteRecord(
          timestamp: '',
          technology: 'LTE',
          cellType: 'FDD-LTE',
          status: '0',
          mcc: '334',
          mnc: '020',
          lac: '1202',
          cellId: '390113',
          eNodeB: '6096',
          sector: '3',
          pci: '124',
          band: '7',
          earfcn: '1350',
          freqDlMhz: '2120.0',
          freqUlMhz: '1930.0',
          rssi: '-80',
          rsrp: '-105',
          rsrq: '-12',
          sinr: '7',
          operator: 'Telcel',
          longitude: '-99.1400000',
          latitude: '19.4400000',
          capturedAt: '2026-04-10T23:52:02.000Z',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScanDataSection.lte(
                subtitle: '2 records',
                filename: 'lilygo_lte_sample.csv',
                rows: rows,
                onDownload: () {},
                onClear: () {},
                onUpload: () async {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PaginatedDataTable), findsOneWidget);
      expect(find.text('Telcel'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
