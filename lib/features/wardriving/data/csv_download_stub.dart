import '../domain/csv_exporter.dart';
import '../domain/models.dart';

void downloadCsvFile(ScanType type, List<Object> rows, String filename) {
  throw UnsupportedError('CSV download is only available on Flutter Web.');
}

void downloadTextFile(String content, String filename) {
  throw UnsupportedError('CSV download is only available on Flutter Web.');
}
