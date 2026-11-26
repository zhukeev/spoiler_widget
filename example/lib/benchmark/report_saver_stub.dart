/// Fallback used on platforms without dart:io (web).
Future<String?> saveBenchmarkReport(String fileName, String contents) async =>
    null;
