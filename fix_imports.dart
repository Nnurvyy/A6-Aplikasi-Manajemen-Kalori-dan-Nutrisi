import 'package:path/path.dart' as p;
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final pkgName = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(pubspec)?.group(1)?.trim() ?? 'nutritrack_app';
  
  final allDartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  Map<String, List<String>> fileMap = {};
  for (var file in allDartFiles) {
    String name = p.basename(file.path);
    fileMap.putIfAbsent(name, () => []).add(p.normalize(file.path).replaceAll('\\', '/'));
  }

  for (var file in allDartFiles) {
    String content = file.readAsStringSync();
    String fileDir = file.parent.path.replaceAll('\\', '/');
    bool changed = false;
    
    final importRegex = RegExp(r'''(import|part|export)\s+['"]([^'"]+)['"]''');
    content = content.replaceAllMapped(importRegex, (match) {
      String directive = match.group(1)!;
      String importPath = match.group(2)!;
      
      if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
        if (importPath.startsWith('package:$pkgName/')) {
           String pkgRelative = importPath.replaceFirst('package:$pkgName/', 'lib/');
           if (!File(pkgRelative).existsSync()) {
               String name = p.basename(importPath);
               if (fileMap.containsKey(name) && fileMap[name]!.isNotEmpty) {
                   String bestMatch = _getBestMatch(fileMap[name]!, fileDir);
                   String newPkgPath = bestMatch.replaceFirst('lib/', '');
                   changed = true;
                   return "$directive 'package:$pkgName/$newPkgPath'";
               }
           }
        }
        return match.group(0)!; 
      }
      
      // Resolve relative import
      String resolvedAbsolute = p.normalize(p.join(fileDir, importPath)).replaceAll('\\', '/');
      
      if (!File(resolvedAbsolute).existsSync()) {
        String name = p.basename(importPath);
        if (fileMap.containsKey(name) && fileMap[name]!.isNotEmpty) {
          String bestMatch = _getBestMatch(fileMap[name]!, fileDir);
          
          if (directive == 'import' || directive == 'export') {
            String newPkgPath = bestMatch.replaceFirst('lib/', '');
            changed = true;
            return "$directive 'package:$pkgName/$newPkgPath'";
          } else if (directive == 'part') {
             String rel = p.relative(bestMatch, from: fileDir).replaceAll('\\', '/');
             changed = true;
             return "part '$rel'";
          }
        }
      }
      
      return match.group(0)!;
    });
    
    if (changed) {
      print('Fixed imports in ${file.path}');
      file.writeAsStringSync(content);
    }
  }
}

String _getBestMatch(List<String> candidates, String currentFileDir) {
  if (candidates.length == 1) return candidates.first;
  int maxScore = -1;
  String best = candidates.first;
  List<String> curParts = currentFileDir.split('/');
  for (var cand in candidates) {
    int score = 0;
    List<String> candParts = cand.split('/');
    for (int i=0; i<candParts.length && i<curParts.length; i++) {
        if (candParts[i] == curParts[i]) score++;
        else break;
    }
    if (score > maxScore) {
        maxScore = score;
        best = cand;
    }
  }
  return best;
}
