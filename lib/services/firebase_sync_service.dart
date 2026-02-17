import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import '../models/student_model.dart';  // ← CHANGED: Now using student_model.dart

class FirebaseSyncService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  // Progress callback for UI updates
  Function(double progress)? onProgress;
  Function(String message)? onStatus;

  FirebaseSyncService({
    this.onProgress,
    this.onStatus,
  });

  // Main sync function
  Future<Map<String, dynamic>> syncSheetToFirebase({
    required String spreadsheetId,
    required String apiKey,
    required String sheetName,
  }) async {
    try {
      onStatus?.call('📡 Fetching data from Google Sheets...');
      
      // 1. Fetch from Google Sheets
      final sheetData = await _fetchFromGoogleSheets(
        spreadsheetId: spreadsheetId,
        apiKey: apiKey,
        sheetName: sheetName,
      );
      
      if (sheetData.isEmpty) {
        return {
          'success': false,
          'message': 'No data found in Google Sheet',
        };
      }

      onStatus?.call('✅ Found ${sheetData.length} student records');
      onProgress?.call(0.3);

      // 2. Convert to JSON format using StudentModel
      final jsonData = <String, dynamic>{};
      var index = 0;
      
      for (var entry in sheetData.entries) {
        jsonData[entry.key] = entry.value.toJson();  // StudentModel has toJson()
        index++;
        onProgress?.call(0.3 + (0.4 * (index / sheetData.length)));
      }

      onStatus?.call('📤 Uploading to Firebase...');
      
      // 3. Upload to Firebase
      await _dbRef.child('exam_data').set(jsonData);
      await _dbRef.child('metadata').set({
        'lastSync': ServerValue.timestamp,
        'recordCount': sheetData.length,
        'syncSource': 'Google Sheets',
        'spreadsheetId': spreadsheetId,
      });

      onProgress?.call(1.0);
      onStatus?.call('✅ Sync complete!');

      return {
        'success': true,
        'message': 'Successfully synced ${sheetData.length} students',
        'count': sheetData.length,
      };
      
    } catch (e) {
      onStatus?.call('❌ Error: $e');
      return {
        'success': false,
        'message': 'Sync failed: $e',
      };
    }
  }

  // Fetch from Google Sheets
  Future<Map<String, StudentModel>> _fetchFromGoogleSheets({
    required String spreadsheetId,
    required String apiKey,
    required String sheetName,
  }) async {
    try {
      final url = 'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$sheetName?key=$apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch sheet: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final rows = data['values'] as List<dynamic>;
      
      if (rows.isEmpty) {
        return {};
      }

      // Get headers (first row)
      final headers = rows[0].map((h) => h.toString()).toList();
      final result = <String, StudentModel>{};

      // Process data rows (skip header)
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= headers.length) {
          final Map<String, dynamic> rowData = {};
          for (var j = 0; j < headers.length; j++) {
            rowData[headers[j]] = row[j].toString();
          }
          final student = StudentModel.fromJson(rowData);
          result[student.studentId] = student;  // Using studentId as key
        }
      }

      return result;
    } catch (e) {
      throw Exception('Google Sheets error: $e');
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final snapshot = await _dbRef.child('metadata').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting sync status: $e');
    }
    return {
      'lastSync': null,
      'recordCount': 0,
    };
  }

  // Clear Firebase data (optional)
  Future<bool> clearFirebaseData() async {
    try {
      await _dbRef.child('exam_data').remove();
      await _dbRef.child('metadata').remove();
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}