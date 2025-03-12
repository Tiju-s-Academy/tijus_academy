import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../routes/app_router.dart';
import '../services/auth_state_provider.dart';
import 'package:url_launcher/url_launcher.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isWebViewSupported = false;

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
  }

  void _checkPlatformSupport() {
    // Check if the current platform supports WebView
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isWebViewSupported = true;
      _setupWebView();
    } else {
      _isWebViewSupported = false;
      _isLoading = false;
    }
  }

  void _setupWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://learn.tijusacademy.com'));
  }

  void _handleLogout() async {
    try {
      // Use the AuthStateProvider from the widget tree
      await Provider.of<AuthStateProvider>(context, listen: false).logout();
      if (!mounted) return;
      // Navigate to login screen after logout using GoRouter
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tijus Academy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isWebViewSupported 
        ? Stack(
            children: [
              WebViewWidget(
                controller: _webViewController!,
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          )
        : _buildFallbackUI(),
    );
  }
  
  Widget _buildFallbackUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'WebView not supported on this platform',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please access the content from a mobile device',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
            onPressed: () async {
              // Store context and mounted status before async operation
              final BuildContext currentContext = context;
              final Uri url = Uri.parse('https://learn.tijusacademy.com');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  // Check if widget is still mounted before using context
                  if (!mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('Could not open the website')),
                  );
                }
              } catch (e) {
                // Check if widget is still mounted before using context
                if (!mounted) return;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(content: Text('Error opening browser: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
