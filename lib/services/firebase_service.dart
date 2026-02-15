import 'package:firebase_database/firebase_database.dart';
import '../models/config_model.dart';

class FirebaseService {
  final DatabaseReference _configRef = 
      FirebaseDatabase.instance.ref().child('exam_config');

  Future<ConfigModel?> getCurrentConfig() async {
    try {
      final snapshot = await _configRef.get();
      if (snapshot.exists) {
        // Fix: Cast the snapshot value properly
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return ConfigModel.fromJson(data);
      }
    } catch (e) {
      print('Error fetching config: $e');
    }
    return null;
  }

  Future<bool> updateConfig(String spreadsheetId, String apiKey) async {
    try {
      final config = ConfigModel(
        spreadsheetId: spreadsheetId,
        apiKey: apiKey,
        lastUpdated: DateTime.now(),
      );
      
      await _configRef.set(config.toJson());
      return true;
    } catch (e) {
      print('Error updating config: $e');
      return false;
    }
  }
}