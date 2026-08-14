import 'dart:async';
import 'dart:html' as html;
import 'csv_file_picker_interface.dart';

Future<PickedCsvData?> pickCsvFileNative() async {
  final completer = Completer<PickedCsvData?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = '.csv,text/csv,text/plain';
  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();
    reader.readAsText(file);

    reader.onLoadEnd.listen((event) {
      final text = reader.result as String? ?? '';
      if (!completer.isCompleted) {
        completer.complete(PickedCsvData(
          fileName: file.name,
          content: text,
          byteLength: file.size,
        ));
      }
    });

    reader.onError.listen((error) {
      if (!completer.isCompleted) {
        completer.completeError('Failed to read file: $error');
      }
    });
  });

  return completer.future;
}
