import 'marauder_models.dart';

final _fileRowRe = RegExp(r'^(.+)\t(\d+)$');
final _totalUsedRe = RegExp(r'^Total used:\s*([\d]+)\s*\/\s*([\d]+)\s*bytes');

SpiffsParseResult? parseSpiffsLine(String line, SpiffsParseMode mode) {
  final plain = line.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  if (plain.isEmpty || plain.startsWith('>')) return null;

  if (mode == SpiffsParseMode.listing) {
    final fileMatch = _fileRowRe.firstMatch(plain);
    if (fileMatch != null) {
      return SpiffsParseResult.fileEntry(
        name: fileMatch.group(1)!,
        size: int.parse(fileMatch.group(2)!),
      );
    }

    final totalMatch = _totalUsedRe.firstMatch(plain);
    if (totalMatch != null) {
      return SpiffsParseResult.listComplete(
        usedBytes: int.parse(totalMatch.group(1)!),
        totalBytes: int.parse(totalMatch.group(2)!),
      );
    }
  }

  if (mode == SpiffsParseMode.reading) {
    if (plain == '[SPIFFS/BEGIN]') {
      return SpiffsParseResult.readBegin();
    }
    if (plain == '[SPIFFS/END]') {
      return SpiffsParseResult.readEnd();
    }
    return SpiffsParseResult.readChunk(plain);
  }

  return null;
}

String formatSpiffsSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
