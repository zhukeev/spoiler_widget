import 'dart:io';

/// Writes [contents] to the platform temp dir and returns the file path.
///
/// On the iOS simulator and desktop targets the temp dir maps to the host
/// filesystem, so reports are directly collectable. On physical devices the
/// file lands in the app sandbox; pull it via devicectl or read it back
/// through the VM service.
Future<String?> saveBenchmarkReport(String fileName, String contents) async {
  try {
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(contents);
    return file.path;
  } catch (_) {
    return null;
  }
}
