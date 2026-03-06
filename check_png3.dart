import 'dart:io';
import 'dart:typed_data';

void checkDims(String path, File out) {
  final file = File(path);
  if (!file.existsSync()) {
    out.writeAsStringSync('\$path not found\n', mode: FileMode.append);
    return;
  }
  final bytes = file.readAsBytesSync();
  if (bytes.length < 24) return;
  final width = ByteData.view(bytes.buffer).getUint32(16);
  final height = ByteData.view(bytes.buffer).getUint32(20);
  out.writeAsStringSync('$path: $width x $height\n', mode: FileMode.append);
}

void main() {
  final out = File('out.txt');
  if (out.existsSync()) out.deleteSync();
  checkDims('assets/sprites/stalker/stalker_walk_horizontal.png', out);
  checkDims('assets/sprites/stalker/stalker_walk_espaldas.png', out);
  checkDims('assets/sprites/stalker/stalker_walk_defrente.png', out);
  checkDims('assets/sprites/stalker/stalker_parado.png', out);
}
