import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CrmApiService {
  static const String _directApiUrl = 'https://learn.tijusacademy.com/api';
  static const String _proxyUrl = 'http://localhost:3000/api'; // Default proxy URL
  
  String _baseUrl = _directApiUrl; // Default to direct API
  bool _useProxy = false; // Toggle flag to switch between direct and proxy
  
  final _client = http.Client();
  static const _timeout = Duration(seconds: 10);
  
  /// Get the current base URL
  String get currentBaseUrl => _baseUrl;
  
  /// Check if proxy is being used
  bool get isUsingProxy => _useProxy;
  
  /// Toggle between direct API and proxy
  void toggleProxy({bool? useProxy}) {
    _useProxy = useProxy ?? !_useProxy;
    _baseUrl = _useProxy ? _proxyUrl : _directApiUrl;
    debugPrint('CRM API now using ${_useProxy ? "PROXY" : "DIRECT"} mode');
    debugPrint('CRM API base URL: $_baseUrl');
  }
  
  /// Set a custom proxy URL (for testing with different proxies)
  void setCustomProxyUrl(String proxyUrl) {
    if (_useProxy) {
      _baseUrl = proxyUrl;
      debugPrint('CRM API custom proxy URL set: $_baseUrl');
    } else {
      debugPrint('Cannot set custom proxy URL when proxy is disabled. Enable proxy first with toggleProxy().');
    }
  }

  /// Creates a lead in the CRM when a user signs up
  Future<void> createLead({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      // Debug: Print the URL and request body
      final url = Uri.parse('$_baseUrl/signup');
      debugPrint('CRM API calling URL: $url');
      
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
      };
      debugPrint('CRM API request body: ${jsonEncode(requestBody)}');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final leadId = jsonDecode(response.body)['lead_id'];
        debugPrint('CRM Lead created: $leadId (${_useProxy ? "PROXY mode" : "DIRECT mode"})');
      } else {
        // Log the error response
        debugPrint('CRM API error: ${response.statusCode}, ${response.body}');
      }
    } on TimeoutException {
      debugPrint('CRM API timeout');
    } catch (e) {
      if (e is http.ClientException) {
        // This is often related to CORS issues when testing locally
        debugPrint('CRM ClientException: ${e.message}');
        debugPrint('This may be due to CORS restrictions when testing locally.');
        debugPrint('The API should work in production environment.');
      } else {
        debugPrint('CRM Error Type: ${e.runtimeType}');
        debugPrint('CRM Error Details: ${e.toString()}');
        
        // Print stack trace in debug mode for better troubleshooting
        if (kDebugMode) {
          debugPrint('Stack trace: ${StackTrace.current}');
        }
      }
    }
  }

  /// Tests the API connection by making a simple GET request to the base URL
  /// Returns true if the connection is successful, false otherwise
  Future<bool> testApiConnection() async {
    try {
      // Debug: Print the URL
      final url = Uri.parse(_baseUrl);
      debugPrint('CRM API testing connection to URL: $url');
      
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
      ).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('CRM API connection successful: ${response.statusCode} (${_useProxy ? "PROXY mode" : "DIRECT mode"})');
        return true;
      } else {
        debugPrint('CRM API connection failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } on TimeoutException {
      debugPrint('CRM API connection timeout');
      return false;
    } catch (e) {
      if (e is http.ClientException) {
        // This is often related to CORS issues when testing locally
        debugPrint('CRM API connection ClientException: ${e.message}');
        debugPrint('This may be due to CORS restrictions when testing locally.');
        debugPrint('The API should work in production environment.');
      } else {
        debugPrint('CRM API connection Error Type: ${e.runtimeType}');
        debugPrint('CRM API connection Error Details: ${e.toString()}');
        
        // Print stack trace in debug mode for better troubleshooting
        if (kDebugMode) {
          debugPrint('Stack trace: ${StackTrace.current}');
        }
      }
      return false;
    }
  }
}
