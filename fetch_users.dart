import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.get(Uri.parse('http://35.154.150.95:3000/users'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    for (var user in data) {
      final uEmail = user['email']?.toString().toLowerCase() ?? '';
      if (uEmail.contains('teacher@gmail') || uEmail.contains('vsp250489') || uEmail.contains('patilvaishali')) {
        print(user);
      }
    }
  }
}
