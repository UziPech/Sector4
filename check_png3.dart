import 'dart:io';
import 'dart:typed_data';

void checkDims(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    print('\$path not found');
    return;
  }
  final bytes = file.readAsBytesSync();
  if (bytes.length < 24) return;
  final width = ByteData.view(bytes.buffer).getUint32(16);
  final height = ByteData.view(bytes.buffer).getUint32(20);
  print('\$path: \$width x \$height');
}

void main() {
  checkDims('assets/sprites/dan_walk_north.png');
  checkDims('assets/sprites/dan_walk_south.png');
}
