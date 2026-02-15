import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import '../services/test_service.dart';
import '../models/config_model.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sheetController = TextEditingController();
  final _apiController = TextEditingController();
  
  final FirebaseService _firebaseService = FirebaseService();
  final TestService _testService = TestService();
  
  bool _isLoading = true;
  bool _isTesting = false;
  ConfigModel? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    
    final config = await _firebaseService.getCurrentConfig();
    if (config != null) {
      setState(() {
        _currentConfig = config;
        _sheetController.text = config.spreadsheetId;
        _apiController.text = config.apiKey;
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isTesting = true);
    Provider.of<AdminState>(context, listen: false).clearMessages();
    
    final result = await _testService.testConnection(
      _sheetController.text.trim(),
      _apiController.text.trim(),
    );
    
    if (result['success']) {
      _showSuccessDialog(result);
    } else {
      Provider.of<AdminState>(context, listen: false)
          .setError(result['message']);
    }
    
    setState(() => _isTesting = false);
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result['message'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Found ${result['count']} students'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    final state = Provider.of<AdminState>(context, listen: false);
    state.setLoading(true);
    state.clearMessages();
    
    final success = await _firebaseService.updateConfig(
      _sheetController.text.trim(),
      _apiController.text.trim(),
    );
    
    if (success) {
      state.setSuccess('✅ Configuration updated successfully!');
      await _loadConfig();
    } else {
      state.setError('❌ Failed to update configuration');
    }
    
    state.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CretCom Admin'),
      ),
      body: Consumer<AdminState>(
        builder: (context, state, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
                const SizedBox(height: 10),
                const Text(
                  'Exam Sheet Configuration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                if (_currentConfig != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Current Configuration:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Sheet: ${_currentConfig!.spreadsheetId}'),
                        Text('Last: ${_currentConfig!.lastUpdated}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _sheetController,
                            decoration: const InputDecoration(
                              labelText: 'Spreadsheet ID',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.table_chart),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _apiController,
                            decoration: const InputDecoration(
                              labelText: 'API Key',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.key),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isTesting ? null : _testConnection,
                                  icon: _isTesting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: Text(_isTesting ? 'Testing...' : 'Test'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (state.isLoading || _isTesting)
                                      ? null
                                      : _saveConfig,
                                  icon: const Icon(Icons.save),
                                  label: Text(state.isLoading ? 'Saving...' : 'Update'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (state.error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: Text(state.error!),
                  ),
                
                if (state.success != null)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    color: Colors.green.shade50,
                    child: Text(state.success!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}