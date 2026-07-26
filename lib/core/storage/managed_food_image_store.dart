import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

typedef DirectoryProvider = Future<Directory> Function();

abstract interface class ManagedFoodImageStore {
  Future<void> clear();
}

final class ApplicationFoodImageStore implements ManagedFoodImageStore {
  const ApplicationFoodImageStore({
    DirectoryProvider applicationSupportDirectory = getApplicationSupportDirectory,
  }) : _applicationSupportDirectory = applicationSupportDirectory;

  static const String directoryName = 'food_images';

  final DirectoryProvider _applicationSupportDirectory;

  Future<Directory> directory() async {
    final Directory root = await _applicationSupportDirectory();
    return Directory(path.join(root.path, directoryName));
  }

  @override
  Future<void> clear() async {
    final Directory managedDirectory = await directory();
    if (await managedDirectory.exists()) {
      await managedDirectory.delete(recursive: true);
    }
  }
}
