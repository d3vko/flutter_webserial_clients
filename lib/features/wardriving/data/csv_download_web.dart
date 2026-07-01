// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/csv_exporter.dart';
import '../domain/models.dart';

void downloadCsvFile(ScanType type, List<Object> rows, String filename) {
  final csv = buildCsv(type, rows);
  final parts = <web.BlobPart>[csv.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

void downloadTextFile(String content, String filename) {
  final parts = <web.BlobPart>[content.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
