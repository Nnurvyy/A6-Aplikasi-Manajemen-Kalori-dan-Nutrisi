import 'package:path/path.dart' as p;
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final featuresDir = Directory('lib/features');
  
  if (!featuresDir.existsSync()) {
    print('features dir not found');
    return;
  }
  
  String pubspec = File('pubspec.yaml').readAsStringSync();
  String pkgName = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(pubspec)?.group(1)?.trim() ?? 'nutritrack_app';
  
  final allDartFiles = featuresDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  final Map<String, String> moves = {};
  
  for (var file in allDartFiles) {
    String originalPath = p.normalize(file.path);
    String fileName = p.basename(originalPath);
    String dirName = p.dirname(originalPath);
    
    // Determine category
    String category = '';
    if (fileName.endsWith('_controller.dart')) {
      category = 'controllers';
    } else if (fileName.endsWith('_model.dart') || fileName.endsWith('_model.g.dart') || dirName.split(Platform.pathSeparator).contains('models') || dirName.split(Platform.pathSeparator).contains('model')) {
      category = 'models';
    } else if (fileName.endsWith('_view.dart') || fileName.endsWith('_screen.dart') || fileName.endsWith('_page.dart') || fileName.endsWith('_dialog.dart') || fileName.endsWith('_sheet.dart') || fileName.endsWith('_widget.dart') || fileName.endsWith('_painter.dart') || dirName.split(Platform.pathSeparator).contains('widgets')) {
      category = 'views';
    } else {
      continue; 
    }
    
    // Determine base feature dir
    List<String> pathParts = p.split(dirName);
    List<String> excludeDirs = ['models', 'model', 'views', 'controllers', 'widgets', 'ui'];
    
    List<String> baseParts = [];
    String subPathForWidget = '';
    
    for (int i = 0; i < pathParts.length; i++) {
      if (excludeDirs.contains(pathParts[i])) {
        if (pathParts[i] == 'widgets') {
          subPathForWidget = 'widgets';
        }
        break; // Stop adding to base parts
      }
      baseParts.add(pathParts[i]);
    }
    
    String baseDir = p.joinAll(baseParts);
    
    String targetPath;
    if (category == 'views' && (subPathForWidget.isNotEmpty || fileName.endsWith('_widget.dart') || fileName.endsWith('_dialog.dart') || fileName.endsWith('_sheet.dart'))) {
      targetPath = p.join(baseDir, 'views', 'widgets', fileName);
    } else {
      targetPath = p.join(baseDir, category, fileName);
    }
    
    if (originalPath != targetPath) {
      moves[originalPath] = targetPath;
    }
  }

  // Calculate import mappings
  Map<String, String> importMappings = {};
  moves.forEach((oldP, newP) {
    String oldPackagePath = oldP.replaceAll('\\', '/').replaceFirst('lib/', '');
    String newPackagePath = newP.replaceAll('\\', '/').replaceFirst('lib/', '');
    importMappings[oldPackagePath] = newPackagePath;
  });

  // Move files
  moves.forEach((oldP, newP) {
    print('Moving $oldP -> $newP');
    final targetFile = File(newP);
    if (!targetFile.parent.existsSync()) {
      targetFile.parent.createSync(recursive: true);
    }
    File(oldP).renameSync(newP);
  });

  // Clean up empty directories in features
  _cleanEmptyDirs(featuresDir);

  // Update imports in all lib files
  final allLibFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  for (var file in allLibFiles) {
    String content = file.readAsStringSync();
    bool changed = false;
    
    // Simple package import replace
    importMappings.forEach((oldPkg, newPkg) {
      String importStr = "package:$pkgName/$oldPkg";
      String newImportStr = "package:$pkgName/$newPkg";
      if (content.contains(importStr)) {
        content = content.replaceAll(importStr, newImportStr);
        changed = true;
      }
    });

    // Also handle relative imports
    String fileDir = file.parent.path.replaceAll('\\', '/');
    
    final importRegex = RegExp(r'''import\s+['"]([^'"]+)['"]''');
    content = content.replaceAllMapped(importRegex, (match) {
      String importPath = match.group(1)!;
      if (importPath.startsWith('package:')) {
        return match.group(0)!; 
      }
      
      // Resolve relative import
      String resolvedAbsolute = p.normalize(p.join(fileDir, importPath)).replaceAll('\\', '/');
      String resolvedPkgPath = resolvedAbsolute.replaceFirst('lib/', '');
      
      if (importMappings.containsKey(resolvedPkgPath)) {
        // Replace with new package import
        changed = true;
        return "import 'package:$pkgName/${importMappings[resolvedPkgPath]}'";
      }
      
      return match.group(0)!;
    });
    
    // Fix part directives if they contained 'model/'
    final partRegex = RegExp(r'''part\s+['"]([^'"]+)['"]''');
    content = content.replaceAllMapped(partRegex, (match) {
        String partPath = match.group(1)!;
        if (partPath.contains('model/')) {
            String newPartPath = partPath.replaceAll('model/', '');
            changed = true;
            return "part '$newPartPath'";
        }
        return match.group(0)!;
    });

    if (changed) {
      print('Updated imports in ${file.path}');
      file.writeAsStringSync(content);
    }
  }
}

void _cleanEmptyDirs(Directory dir) {
  for (var entity in dir.listSync()) {
    if (entity is Directory) {
      _cleanEmptyDirs(entity);
      if (entity.existsSync() && entity.listSync().isEmpty) {
        entity.deleteSync();
      }
    }
  }
}
