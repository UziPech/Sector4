import 'dart:io';
import 'dart:typed_data';

void main() {
  final file = File('assets/sprites/caminar_dan.png');
  final bytes = file.readAsBytesSync();

  if (bytes.length < 24) {
    print('Not a valid image');
    return;
  }

  final width = ByteData.view(bytes.buffer).getUint32(16);
  final height = ByteData.view(bytes.buffer).getUint32(20);

  print('Width: \$width');
  print('Height: \$height');
}
