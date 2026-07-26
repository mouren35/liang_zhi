import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final Directory libDirectory = Directory('lib');

  test('core 不依赖功能页面', () {
    final Iterable<File> files = _dartFiles(Directory(path.join('lib', 'core')));

    for (final File file in files) {
      final String source = file.readAsStringSync();
      expect(source, isNot(contains('package:liangzhi/features/')), reason: file.path);
    }
  });

  test('页面不直接访问数据库或网络实现', () {
    final Iterable<File> pages = _dartFiles(libDirectory).where(
      (File file) => file.path.endsWith('_page.dart'),
    );

    for (final File page in pages) {
      final String source = page.readAsStringSync();
      expect(source, isNot(contains('core/database/')), reason: page.path);
      expect(source, isNot(contains('core/network/')), reason: page.path);
    }
  });

  test('功能模块不导入其他功能模块内部实现', () {
    final Directory featuresDirectory = Directory(path.join('lib', 'features'));
    for (final File file in _dartFiles(featuresDirectory)) {
      final String relative = path.relative(file.path, from: featuresDirectory.path);
      final String ownFeature = path.split(relative).first;
      final RegExp featureImport = RegExp(r"package:liangzhi/features/([^/]+)/");

      for (final RegExpMatch match in featureImport.allMatches(file.readAsStringSync())) {
        expect(match.group(1), ownFeature, reason: file.path);
      }
    }
  });
}

Iterable<File> _dartFiles(Directory directory) sync* {
  if (!directory.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}
