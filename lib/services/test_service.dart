import 'dart:convert';
import 'package:http/http.dart' as http;

class TestService {
  Future<Map<String, dynamic>> testConnection(
      String spreadsheetId, String apiKey) async {
    try {
      final url = 'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Sheet1?key=$apiKey';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rows = data['values'] as List<dynamic>;
        
        if (rows.isEmpty) {
          return {
            'success': false,
            'message': 'Sheet is empty',
          };
        }
        
        final headers = rows[0];
        return {
          'success': true,
          'message': '✅ Connected! Found ${rows.length - 1} students',
          'headers': headers,
          'count': rows.length - 1,
        };
      } else {
        return {
          'success': false,
          'message': '❌ Error ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Connection failed: $e',
      };
    }
  }
}