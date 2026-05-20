import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/api_providers.dart';
import '../theme/vintage_theme.dart';
import 'desk_dashboard.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  bool _isRegisterMode = false;

  // Sign In controllers
  final TextEditingController _loginUserOrEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Register controllers
  final TextEditingController _registerUsernameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginUserOrEmailController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final apiService = ref.read(apiServiceProvider);

    if (_isRegisterMode) {
      final username = _registerUsernameController.text.trim();
      final email = _registerEmailController.text.trim();
      final password = _registerPasswordController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'All credentials are required to register.';
        });
        return;
      }
    } else {
      final usernameOrEmail = _loginUserOrEmailController.text.trim();
      final password = _loginPasswordController.text.trim();

      if (usernameOrEmail.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Username/Email and Password are required.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User user;
      if (_isRegisterMode) {
        user = await apiService.register(
          _registerUsernameController.text.trim(),
          _registerEmailController.text.trim(),
          _registerPasswordController.text.trim(),
        );
      } else {
        user = await apiService.login(
          _loginUserOrEmailController.text.trim(),
          _loginPasswordController.text.trim(),
        );
      }

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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 28),

                // Skeuomorphic Parchment Tabs
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRegisterMode = false;
                            _errorMessage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: !_isRegisterMode ? VintageTheme.inkBlue : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: !_isRegisterMode ? FontWeight.bold : FontWeight.w500,
                              color: !_isRegisterMode ? VintageTheme.inkBlue : VintageTheme.inkBlue.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRegisterMode = true;
                            _errorMessage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _isRegisterMode ? VintageTheme.inkBlue : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Register Desk',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: _isRegisterMode ? FontWeight.bold : FontWeight.w500,
                              color: _isRegisterMode ? VintageTheme.inkBlue : VintageTheme.inkBlue.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Form Fields
                if (!_isRegisterMode) ...[
                  // LOGIN FIELDS
                  TextField(
                    controller: _loginUserOrEmailController,
                    cursorColor: VintageTheme.inkBlue,
                    style: GoogleFonts.ebGaramond(fontSize: 18, color: VintageTheme.inkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter Username or Email...',
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _loginPasswordController,
                    obscureText: true,
                    cursorColor: VintageTheme.inkBlue,
                    style: GoogleFonts.ebGaramond(fontSize: 18, color: VintageTheme.inkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter Password Key...',
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => _ResetPasswordDialog(
                            apiService: ref.read(apiServiceProvider),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot your password key?',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: VintageTheme.waxSealRed,
                          decoration: TextDecoration.underline,
                          decorationColor: VintageTheme.waxSealRed,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // REGISTER FIELDS
                  TextField(
                    controller: _registerUsernameController,
                    cursorColor: VintageTheme.inkBlue,
                    style: GoogleFonts.ebGaramond(fontSize: 18, color: VintageTheme.inkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter Username...',
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: VintageTheme.inkBlue,
                    style: GoogleFonts.ebGaramond(fontSize: 18, color: VintageTheme.inkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter Email Address...',
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerPasswordController,
                    obscureText: true,
                    cursorColor: VintageTheme.inkBlue,
                    style: GoogleFonts.ebGaramond(fontSize: 18, color: VintageTheme.inkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter Password Key...',
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
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
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
                const SizedBox(height: 28),

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
                          _isRegisterMode ? 'Unlock writing desk' : 'Open writing desk',
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

// Custom Dialog to perform E2E Forgot / Reset Password flow
class _ResetPasswordDialog extends StatefulWidget {
  final ApiService apiService;
  const _ResetPasswordDialog({required this.apiService});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  
  bool _isSending = false;
  bool _hasSent = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _requestToken() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await widget.apiService.forgotPassword(email);
      setState(() {
        _isSending = false;
        _hasSent = true;
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _resetPassword() async {
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    if (token.isEmpty || newPassword.isEmpty) {
      setState(() => _error = 'Token and password are required');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await widget.apiService.resetPassword(token, newPassword);
      setState(() {
        _isSending = false;
        _successMessage = 'Your desk key has been reset successfully!';
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: VintageTheme.paperCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.mark_email_unread_outlined, color: VintageTheme.inkBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reset Desk Key',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: VintageTheme.inkBlue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: VintageTheme.inkBlue),
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: VintageTheme.paperBorder),
            const SizedBox(height: 20),
            if (_successMessage != null) ...[
              Text(
                _successMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: VintageTheme.inkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You may now log in using your new credentials.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: VintageTheme.inkBlue.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VintageTheme.inkBlue,
                  foregroundColor: VintageTheme.parchmentLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: VintageTheme.antiqueGold, width: 1),
                  ),
                ),
                child: Text('Return to Guest Book', style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ] else if (!_hasSent) ...[
              Text(
                'Enter your email below. The Postmaster will write a letter containing your verification reset token.',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  height: 1.4,
                  color: VintageTheme.inkBlue.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                cursorColor: VintageTheme.inkBlue,
                style: GoogleFonts.ebGaramond(fontSize: 16, color: VintageTheme.inkBlue),
                decoration: InputDecoration(
                  hintText: 'Enter your email address...',
                  hintStyle: TextStyle(color: VintageTheme.inkBlue.withOpacity(0.4)),
                  filled: true,
                  fillColor: VintageTheme.parchmentLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: VintageTheme.paperBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: VintageTheme.inkBlue, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.ebGaramond(color: VintageTheme.waxSealRed, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
              _isSending
                  ? const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue))
                  : ElevatedButton(
                      onPressed: _requestToken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VintageTheme.inkBlue,
                        foregroundColor: VintageTheme.parchmentLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: VintageTheme.antiqueGold, width: 1),
                        ),
                      ),
                      child: Text('Dispatch Reset Token', style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ] else ...[
              Text(
                'A reset token has been dispatched! Read the token from the server console or "last_reset_email.txt" in your workspace root and enter it below along with your new key.',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  height: 1.4,
                  color: VintageTheme.inkBlue.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _tokenController,
                cursorColor: VintageTheme.inkBlue,
                style: GoogleFonts.ebGaramond(fontSize: 16, color: VintageTheme.inkBlue),
                decoration: InputDecoration(
                  hintText: 'Enter reset token...',
                  hintStyle: TextStyle(color: VintageTheme.inkBlue.withOpacity(0.4)),
                  filled: true,
                  fillColor: VintageTheme.parchmentLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: VintageTheme.paperBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: VintageTheme.inkBlue, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                cursorColor: VintageTheme.inkBlue,
                style: GoogleFonts.ebGaramond(fontSize: 16, color: VintageTheme.inkBlue),
                decoration: InputDecoration(
                  hintText: 'Enter new password key...',
                  hintStyle: TextStyle(color: VintageTheme.inkBlue.withOpacity(0.4)),
                  filled: true,
                  fillColor: VintageTheme.parchmentLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: VintageTheme.paperBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: VintageTheme.inkBlue, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.ebGaramond(color: VintageTheme.waxSealRed, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
              _isSending
                  ? const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue))
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VintageTheme.inkBlue,
                        foregroundColor: VintageTheme.parchmentLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: VintageTheme.antiqueGold, width: 1),
                        ),
                      ),
                      child: Text('Reset Password Key', style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ]
          ],
        ),
      ),
    );
  }
}
