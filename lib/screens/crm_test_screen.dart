import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api/crm_api_service.dart';
import 'package:flutter/foundation.dart';

class CrmTestScreen extends StatefulWidget {
  const CrmTestScreen({Key? key}) : super(key: key);

  @override
  State<CrmTestScreen> createState() => _CrmTestScreenState();
}

class _CrmTestScreenState extends State<CrmTestScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isLoading = false;

  // Test data for creating a lead
  final String _testName = 'Test User';
  final String _testEmail = 'test@example.com';
  final String _testPhone = '1234567890';

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
      
      // Scroll to the bottom of the logs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
    });

    _addLog('Testing API connection...');
    
    try {
      final crmService = context.read<CrmApiService>();
      final bool isConnected = await crmService.testApiConnection();
      
      _addLog(isConnected 
        ? 'API connection successful! ✅' 
        : 'API connection failed ❌');
    } catch (e) {
      _addLog('Error testing API connection: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestLead() async {
    setState(() {
      _isLoading = true;
    });

    _addLog('Creating test lead...');
    _addLog('Name: $_testName');
    _addLog('Email: $_testEmail');
    _addLog('Phone: $_testPhone');
    
    try {
      final crmService = context.read<CrmApiService>();
      await crmService.createLead(
        name: _testName,
        email: _testEmail,
        phone: _testPhone,
      );
      
      _addLog('Lead creation request completed. Check debug console for details.');
    } catch (e) {
      _addLog('Error creating lead: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM API Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action buttons
            // API Mode toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'API Connection Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Builder(
                          builder: (context) {
                            final crmService = context.watch<CrmApiService>();
                            return Switch(
                              value: crmService.isUsingProxy,
                              onChanged: _isLoading 
                                ? null 
                                : (value) {
                                    setState(() {
                                      crmService.toggleProxy(useProxy: value);
                                      _addLog('Switched to ${value ? "PROXY" : "DIRECT"} mode');
                                      _addLog('API URL: ${crmService.currentBaseUrl}');
                                    });
                                  },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final crmService = context.watch<CrmApiService>();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Current mode:'),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    crmService.isUsingProxy ? 'PROXY' : 'DIRECT', 
                                    style: TextStyle(
                                      color: crmService.isUsingProxy ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: crmService.isUsingProxy 
                                    ? Colors.blue 
                                    : Colors.amber,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'API URL: ${crmService.currentBaseUrl}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            if (crmService.isUsingProxy) 
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'To use proxy mode, make sure the CORS proxy is running on port 3000. '
                                        'Run Node.js proxy with: node cors-proxy.js',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.network_check),
                    label: const Text('Test API Connection'),
                    onPressed: _isLoading ? null : _testApiConnection,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create Test Lead'),
                    onPressed: _isLoading ? null : _createTestLead,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Loading indicator
            if (_isLoading)
              const LinearProgressIndicator(),
            
            const SizedBox(height: 8),
            
            // Log header
            const Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text(
                  'Test Results:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // Logs area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        _logs[index],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: _logs[index].contains('❌') 
                            ? Colors.red[700]
                            : _logs[index].contains('✅')
                              ? Colors.green[700]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Test data information
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Lead Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: $_testName'),
                    Text('Email: $_testEmail'),
                    Text('Phone: $_testPhone'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CORS Information Card
            Card(
              child: ExpansionTile(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'CORS Issues in Local Testing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                initiallyExpanded: false,
                childrenPadding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'What is CORS?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cross-Origin Resource Sharing (CORS) is a security feature implemented by browsers '
                    'that blocks web applications from making requests to a different domain than the one '
                    'that served the web app. When testing locally, your Flutter web app is served from '
                    'localhost, but it\'s making requests to learn.tijusacademy.com, which causes CORS errors.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Solutions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Solution 1
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.black54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Configure the server to allow CORS: Add the following headers to your API responses:\n'
                          '  • Access-Control-Allow-Origin: *\n'
                          '  • Access-Control-Allow-Methods: GET, POST, OPTIONS\n'
                          '  • Access-Control-Allow-Headers: Content-Type',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Solution 2
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.black54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use a CORS proxy for testing: Use a service like cors-anywhere.herokuapp.com or '
                          'create a local proxy with tools like local-cors-proxy.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Solution 3
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.black54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create a simple backend proxy: Create a small server (using Express, Flask, etc.) '
                          'that runs locally and forwards requests to the actual API, bypassing CORS restrictions.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Setup proxy instructions
                  const Text(
                    'Using the Node.js CORS Proxy:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Make sure Node.js is installed\n'
                    '2. Run the proxy server with command: node cors-proxy.js\n'
                    '3. Toggle the API mode to "PROXY" at the top of this screen\n'
                    '4. The proxy will forward requests to the actual CRM API',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: CORS is only an issue during local development. In production, '
                            'if your API and app are served from the same domain or the API has proper CORS headers, '
                            'this won\'t be a problem.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

