import 'csv_file_picker_interface.dart';
import 'csv_file_picker_stub.dart'
    if (dart.library.html) 'csv_file_picker_web.dart';

export 'csv_file_picker_interface.dart';

Future<PickedCsvData?> pickCsvFile() => pickCsvFileNative();
