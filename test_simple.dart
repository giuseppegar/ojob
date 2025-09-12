// Simple test to verify file operations work
import 'dart:io';

void main() async {
  print('🧪 Test semplice operazioni file...\n');
  
  try {
    // Test in Downloads directory (should have permission)
    final downloadsDir = '${Platform.environment['HOME']}/Downloads';
    print('📁 Directory test: $downloadsDir');
    
    final testFile = File('$downloadsDir/test_job_schedule.txt');
    final content = 'TEST123  456 789';
    
    // Write file
    await testFile.writeAsString(content);
    print('✅ File scritto: ${testFile.path}');
    
    // Read file
    if (await testFile.exists()) {
      String readContent = await testFile.readAsString();
      print('✅ File letto: "$readContent"');
      
      // Cleanup
      await testFile.delete();
      print('🧹 File eliminato');
      
      print('\n✅ Tutti i test passano! Il problema è solo nel file picker.');
    }
  } catch (e) {
    print('❌ Errore: $e');
  }
}