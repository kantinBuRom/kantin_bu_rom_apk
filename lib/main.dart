import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  String _getPreferredUrl() {
    const String httpsUrl = 'https://kantinburom.github.io/';
    const String httpUrl = 'http://kantinburom.github.io/';
    try {
      // Try loading HTTPS first
      return httpsUrl;
    } catch (e) {
      // Fallback to HTTP if HTTPS fails
      return httpUrl;
    }
  }

  Future<void> _initializeWebView() async {
    if (_controller != null) return; // Prevent re-initialization

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              _updateBackButtonState();
              setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              setState(() {
                _errorMessage = 'Failed to load page: ${error.description}';
                _isLoading = false;
              });
            },
            onNavigationRequest: (request) {
              final url = request.url.toLowerCase();

              // Handle mailto links
              if (url.startsWith('mailto:')) {
                _launchUrl(Uri.parse(url));
                return NavigationDecision.prevent;
              }

              // Handle WhatsApp links
              if (url.startsWith('https://api.whatsapp.com/') ||
                  url.startsWith('https://wa.me/')) {
                _launchUrl(Uri.parse(url));
                return NavigationDecision.prevent;
              }

              // Handle intent links
              if (url.startsWith('intent://')) {
                _handleIntentUrl(url);
                return NavigationDecision.prevent;
              }

              // handle facebook links
              if (url.startsWith('https://www.facebook.com/') || url.startsWith('https://m.facebook.com/') || url.startsWith('https://www.messenger.com/') || url.startsWith('fb://')) {
                String modifiedUrl = url;
                if (modifiedUrl.startsWith('fb://')) {
                  modifiedUrl = modifiedUrl.replaceFirst('fb://', 'https://');
                }
                _launchUrl(Uri.parse(modifiedUrl));
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_getPreferredUrl()));

      setState(() {
        _controller = controller;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing WebView: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(Uri uri) async {
    try {
      if (uri.scheme == 'mailto') {
        // Try to launch email app first
        if (await canLaunchUrl(uri)) {
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            // If email app launch fails, try Gmail in browser
            final webGmailUrl = Uri.parse(
                'https://mail.google.com/mail/?view=cm&fs=1&to=${uri.path}&su=&body='
            );
            if (await canLaunchUrl(webGmailUrl)) {
              await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
            } else {
              throw 'Could not launch email client or web Gmail';
            }
          }
        } else {
          // If no email app available, try web Gmail
          final webGmailUrl = Uri.parse(
              'https://mail.google.com/mail/?view=cm&fs=1&to=${uri.path}&su=&body='
          );
          if (await canLaunchUrl(webGmailUrl)) {
            await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch email client or web Gmail';
          }
        }
      } else {
        // Handle other URLs as before
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $uri';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open: $e'),
            action: SnackBarAction(
              label: 'Try in Browser',
              onPressed: () async {
                // Fallback to opening in browser
                final webUrl = uri.scheme == 'mailto'
                    ? Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=${uri.path}&su=&body=')
                    : uri;
                try {
                  await launchUrl(
                    webUrl,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to open in browser: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleIntentUrl(String url) async {
    try {
      // final packageName = RegExp(r'package=([\w\.]+)').firstMatch(url)?.group(1);
      final packageName = RegExp(r'package=([\w.]+)').firstMatch(url)?.group(1);

      if (packageName != null) {
        final playStoreUrl = 'market://details?id=$packageName';
        final Uri uri = Uri.parse(playStoreUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          final fallbackUri = Uri.parse(
              'https://play.google.com/store/apps/details?id=$packageName'
          );
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open app: $e')),
        );
      }
    }
  }

  Future<void> _updateBackButtonState() async {
    if (_controller != null) {
      final canGoBack = await _controller!.canGoBack();
      setState(() {
        _canGoBack = canGoBack;
      });
    }
  }

  Future<bool> _handlePopPage() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (bool didPop, result) async {
        if (!didPop) {
          await _handlePopPage();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.orange,
            statusBarIconBrightness: Brightness.light,
          ),
          backgroundColor: Colors.orange,
          leading: _canGoBack
              ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (_controller != null && await _controller!.canGoBack()) {
                _controller!.goBack();
              }
            },
          )
              : null,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://kantinburom.github.io/assets/img/logo.png',
                height: 30,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.restaurant, color: Colors.white);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Kantin Bu Rom',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 2,
          shadowColor: Colors.black26,
        ),
        body: Stack(
          children: [
            if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                          _controller = null; // Reset controller
                        });
                        _initializeWebView();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_controller != null)
              WebViewWidget(controller: _controller!),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
