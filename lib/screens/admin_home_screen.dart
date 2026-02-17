import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import '../services/test_service.dart';
import '../services/firebase_sync_service.dart';
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
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatus = '';
  ConfigModel? _currentConfig;
  Map<String, dynamic> _syncStatusData = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadSyncStatus();
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

  Future<void> _loadSyncStatus() async {
    final syncService = FirebaseSyncService();
    final status = await syncService.getSyncStatus();
    setState(() {
      _syncStatusData = status;
    });
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

  Future<void> _syncToFirebase() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncStatus = 'Starting sync...';
    });

    final syncService = FirebaseSyncService(
      onProgress: (progress) {
        setState(() => _syncProgress = progress);
      },
      onStatus: (status) {
        setState(() => _syncStatus = status);
      },
    );

    final result = await syncService.syncSheetToFirebase(
      spreadsheetId: _sheetController.text.trim(),
      apiKey: _apiController.text.trim(),
      sheetName: 'Sheet1', // or make this configurable
    );

    setState(() => _isSyncing = false);

    if (result['success']) {
      Provider.of<AdminState>(context, listen: false)
          .setSuccess(result['message']);
      await _loadSyncStatus();
    } else {
      Provider.of<AdminState>(context, listen: false)
          .setError(result['message']);
    }
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CretCom Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncStatus,
            tooltip: 'Refresh status',
          ),
        ],
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
                
                // Sync Status Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_sync, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Firebase Sync Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildInfoRow('Last Sync', _formatTimestamp(_syncStatusData['lastSync'])),
                        _buildInfoRow('Records', '${_syncStatusData['recordCount'] ?? 0} students'),
                        if (_syncStatusData.containsKey('spreadsheetId'))
                          _buildInfoRow('Source', 'Google Sheet: ${_syncStatusData['spreadsheetId']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Current Config Card
                if (_currentConfig != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Current Configuration',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildInfoRow('Sheet ID', _currentConfig!.spreadsheetId, maxLength: 30),
                          _buildInfoRow('API Key', '${_currentConfig!.apiKey.substring(0, 15)}...'),
                          _buildInfoRow('Last Updated', _currentConfig!.lastUpdated.toString()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Main Form Card
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
                          
                          // Action Buttons Row
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (state.isLoading || _isTesting) ? null : _saveConfig,
                                  icon: const Icon(Icons.save),
                                  label: Text(state.isLoading ? 'Saving...' : 'Save Config'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Sync Button (NEW)
                          ElevatedButton.icon(
                            onPressed: (_isSyncing || _isTesting) ? null : _syncToFirebase,
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync to Firebase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          
                          // Sync Progress Bar
                          if (_isSyncing) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(value: _syncProgress),
                            const SizedBox(height: 8),
                            Text(_syncStatus),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Status Messages
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

  Widget _buildInfoRow(String label, String value, {int maxLength = 20}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.length > maxLength ? '${value.substring(0, maxLength)}...' : value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}