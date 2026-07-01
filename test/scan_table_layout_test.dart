import 'package:lilygo_wardriving_web/features/wardriving/presentation/widgets/scan_table_layout.dart';
import 'package:test/test.dart';

void main() {
  group('paginatedTableHeight', () {
    test('returns footer and heading only when rowCount is zero', () {
      expect(
        paginatedTableHeight(rowsPerPage: 10, rowCount: 0),
        defaultHeadingRowHeight + kPaginatedTableFooterHeight,
      );
    });

    test(
      'allocates full rowsPerPage slots when rowCount is below page size',
      () {
        expect(
          paginatedTableHeight(rowsPerPage: 10, rowCount: 2),
          defaultHeadingRowHeight +
              10 * defaultDataRowHeight +
              kPaginatedTableFooterHeight +
              tableHeightSafetyPadding,
        );
      },
    );

    test('caps row slots at rowsPerPage when rowCount exceeds page size', () {
      expect(
        paginatedTableHeight(rowsPerPage: 10, rowCount: 25),
        defaultHeadingRowHeight +
            10 * defaultDataRowHeight +
            kPaginatedTableFooterHeight +
            tableHeightSafetyPadding,
      );
    });

    test('recalculates when rowsPerPage increases', () {
      final at10 = paginatedTableHeight(rowsPerPage: 10, rowCount: 15);
      final at20 = paginatedTableHeight(rowsPerPage: 20, rowCount: 15);

      expect(at20, greaterThan(at10));
      expect(
        at20,
        defaultHeadingRowHeight +
            20 * defaultDataRowHeight +
            kPaginatedTableFooterHeight +
            tableHeightSafetyPadding,
      );
    });
  });
}
