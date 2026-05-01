import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test script to send a literal hardcoded key to the staging/live backend
  // to bypass the Flutter UI entirely.

  const String schoolId =
      '51f29b5b-e408-4be0-9a36-d95c863d81ac'; // example testing school
  const String validKey =
      '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'; // Just a random proper-format string (dummy key)

  Map<String, dynamic> keys = {
    'chat': validKey,
    'helpbot': validKey,
    'image': validKey,
    'audio': null,
    'translate': validKey,
    'emmiLite': validKey,
    'blockly': validKey,
  };

  print('Payload keys JSON format:');
  print(jsonEncode({'schoolId': schoolId, 'keys': keys}));

  // Not actually sending to avoid overriding production keys with dummy data,
  // but just verifying the JSON output isn't throwing in hidden \r or \n or weird characters
  // when Dart stringifies it.
}
