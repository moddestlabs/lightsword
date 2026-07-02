import 'dart:io';
import 'dart:typed_data';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';

Future<void> main() async {
  final ntFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntFile.readAsBytes();
  
  final decompressed = ZTextReader.decompressAllBlocks(Uint8List.fromList(ntData), null);
  
  // Add wrapper
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">');
  buffer.writeln('<osisText>');
  buffer.write(decompressed);
  buffer.writeln('</osisText>');
  buffer.writeln('</osis>');
  
  final wrapped = buffer.toString();
  final lines = wrapped.split('\n');
  
  // Error at line 4, column 27076
  // Lines 1-3 are the wrapper, so line 4 is the start of decompressed content
  if (lines.length > 3) {
    final problemLine = lines[3];
    final pos = 27076;
    
    if (pos < problemLine.length) {
      final start = pos > 200 ? pos - 200 : 0;
      final end = pos + 200 < problemLine.length ? pos + 200 : problemLine.length;
      
      print('Context around position $pos (line 4):');
      print(problemLine.substring(start, end));
      print('\n');
      print('Character at position: "${problemLine[pos]}" (code: ${problemLine.codeUnitAt(pos)})');
    }
  }
}
