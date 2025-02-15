import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const KantinBuRomApp());
}

class KantinBuRomApp extends StatelessWidget {
  const KantinBuRomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kantin Bu Rom',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              setState(() {
                _errorMessage = 'Failed to load page: ${error.description}';
                _isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse('https://kantinburom.github.io/'));
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing WebView: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Kantin Bu Rom',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            )),
        centerTitle: true,
        elevation: 4,
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
        ],
      ),
    );
  }
}
