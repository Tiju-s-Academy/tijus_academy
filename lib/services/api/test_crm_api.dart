import 'package:flutter/material.dart';
import 'crm_api_service.dart';

// This is a test script to verify the CRM API functionality
// It can be executed with `flutter run -t lib/services/api/test_crm_api.dart`
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestCrmApi(),
    );
  }
}

class TestCrmApi extends StatefulWidget {
  @override
  _TestCrmApiState createState() => _TestCrmApiState();
}

class _TestCrmApiState extends State<TestCrmApi> {
  final _crmApiService = CrmApiService();
  bool _isLoading = false;
  String _result = 'Press the button to test the CRM API';

  Future<void> _testApiCall() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing API call...';
    });

    try {
      final leadId = await _crmApiService.createLead(
        name: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
      );

      setState(() {
        if (leadId != null) {
          _result = 'Success! Lead created with ID: $leadId';
        } else {
          _result = 'API call completed but no lead ID was returned';
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM API Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _testApiCall,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Test CRM API'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
