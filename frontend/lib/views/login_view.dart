import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/api_providers.dart';
import '../theme/vintage_theme.dart';
import 'desk_dashboard.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name in the register';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(apiServiceProvider).authenticate(username);
      ref.read(sessionProvider.notifier).state = user;
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DeskDashboard()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: VintageTheme.paperCardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Skeuomorphic Quill Logo
                Icon(
                  Icons.edit_road_outlined,
                  size: 48,
                  color: VintageTheme.inkBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'I L K F',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: VintageTheme.inkBlue,
                  ),
                ),
                Text(
                  'A Deliberate Messaging App',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: VintageTheme.inkBlue.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                // Divider line representing ink stroke
                Container(
                  height: 1.5,
                  width: 80,
                  color: VintageTheme.inkBlue.withOpacity(0.3),
                ),
                const SizedBox(height: 40),
                Text(
                  'Write your name in the Guest Book',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: VintageTheme.inkBlue,
                  ),
                ),
                const SizedBox(height: 16),
                // Vintage Style TextField
                TextField(
                  controller: _usernameController,
                  cursorColor: VintageTheme.inkBlue,
                  style: GoogleFonts.ebGaramond(fontSize: 18, color: VintageTheme.inkBlue),
                  decoration: InputDecoration(
                    hintText: 'Enter nickname...',
                    hintStyle: TextStyle(color: VintageTheme.inkBlue.withOpacity(0.4)),
                    filled: true,
                    fillColor: VintageTheme.parchmentLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: VintageTheme.paperBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: VintageTheme.inkBlue, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ebGaramond(
                      color: VintageTheme.waxSealRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator(color: VintageTheme.inkBlue)
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VintageTheme.inkBlue,
                          foregroundColor: VintageTheme.parchmentLight,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: VintageTheme.antiqueGold, width: 1),
                          ),
                        ),
                        child: Text(
                          'Open writing desk',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
