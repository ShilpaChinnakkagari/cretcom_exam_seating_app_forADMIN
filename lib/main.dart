import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CretCom Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => AdminState(),
        child: const AdminHomeScreen(),
      ),
    );
  }
}

class AdminState extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _success;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    _success = null;
    notifyListeners();
  }

  void setSuccess(String? message) {
    _success = message;
    _error = null;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}