import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'csv_file_picker_interface.dart';

Future<PickedCsvData?> pickCsvFileNative() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;

    String content = '';
    if (f.bytes != null) {
      content = utf8.decode(f.bytes!);
    } else if (f.path != null) {
      content = await File(f.path!).readAsString();
    }

    return PickedCsvData(
      fileName: f.name,
      content: content,
      byteLength: f.size,
    );
  } catch (e) {
    if (e.toString().contains('_instance') || e.toString().contains('LateInitializationError')) {
      throw Exception('File picker plugin is not initialized for this platform. Please try "Load Sample" to test ECG predictions.');
    }
    rethrow;
  }
}
