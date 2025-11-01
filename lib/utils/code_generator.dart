import 'dart:math';
import 'package:meta/meta.dart'; // Add 'meta: ^1.12.0' to your pubspec if using this

class CodeGenerator {
  // Annotation helps ensure this function is covered by tests
  @visibleForTesting 
  static String generateEnrollmentCode() {
    final Random random = Random();
    
    // Generate 3 random uppercase letters
    String letters = String.fromCharCodes(
      Iterable.generate(3, (_) => 'A'.codeUnitAt(0) + random.nextInt(26)),
    );

    // Generate 4 random digits
    String digits = random.nextInt(10000).toString().padLeft(4, '0');

    return '$letters-$digits';
  }
}