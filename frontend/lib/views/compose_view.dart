import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/api_providers.dart';
import '../theme/vintage_theme.dart';

class ComposeView extends ConsumerStatefulWidget {
  final String? initialRecipient;
  const ComposeView({super.key, this.initialRecipient});

  @override
  ConsumerState<ComposeView> createState() => _ComposeViewState();
}

class _ComposeViewState extends ConsumerState<ComposeView> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isUnregistered = false;
  double _delaySeconds = 60.0; // Default: 60 seconds (1 minute) for quick testing!
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipient != null) {
      _recipientController.text = widget.initialRecipient!;
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _getDelayLabel() {
    if (_delaySeconds < 60) {
      return '${_delaySeconds.round()} seconds (Instant Carrier)';
    } else if (_delaySeconds < 3600) {
      return '${(_delaySeconds / 60).round()} minutes (Pigeon Courier)';
    } else if (_delaySeconds < 86400) {
      return '${(_delaySeconds / 3600).round()} hours (Horse & Carriage)';
    } else {
      return '${(_delaySeconds / 86400).round()} days (Steam Locomotive)';
    }
  }

  void _sendLetter() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(sessionProvider);
    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    // 1. Show the satisfying skeuomorphic wax sealing animation dialog!
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _WaxSealingDialog(),
    );

    try {
      final recipientUser = _isUnregistered ? '' : _recipientController.text.trim();
      final unregisteredName = _isUnregistered ? _recipientController.text.trim() : '';

      await ref.read(apiServiceProvider).sendLetter(
            senderId: user.id,
            recipientUsername: recipientUser,
            recipientNameUnregistered: unregisteredName,
            subject: _subjectController.text.trim(),
            content: _contentController.text,
            delaySeconds: _delaySeconds.round(),
          );

      // Force Riverpod to refresh outbox and pending
      ref.invalidate(outboxProvider);
      ref.invalidate(pendingLettersProvider);
      ref.invalidate(contactsProvider);

      if (mounted) {
        // Pop the sealing dialog
        Navigator.of(context).pop();
        // Pop the compose screen back to dashboard
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VintageTheme.inkBlue,
            content: Text(
              'Your letter has been folded, sealed with wax, and is now in transit!',
              style: GoogleFonts.ebGaramond(fontSize: 16, color: VintageTheme.parchmentLight),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Pop the sealing dialog
        Navigator.of(context).pop();
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VintageTheme.waxSealRed,
            content: Text(
              'Failed to dispatch courier: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.ebGaramond(fontSize: 16, color: VintageTheme.parchmentLight),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<VintageWritingStyle>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose a New Letter'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Top section (envelope header card)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: VintageTheme.paperCardDecoration(),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _recipientController,
                              cursorColor: VintageTheme.inkBlue,
                              style: GoogleFonts.ebGaramond(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: _isUnregistered ? 'Unregistered recipient name' : 'To (registered username)',
                                labelStyle: const TextStyle(color: VintageTheme.inkBlue),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: VintageTheme.inkBlue, width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please specify recipient' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              const Text('Unregistered', style: TextStyle(fontSize: 10, color: VintageTheme.inkBlue)),
                              Checkbox(
                                activeColor: VintageTheme.inkBlue,
                                checkColor: VintageTheme.parchmentLight,
                                value: _isUnregistered,
                                onChanged: (val) {
                                  setState(() {
                                    _isUnregistered = val ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _subjectController,
                        cursorColor: VintageTheme.inkBlue,
                        style: GoogleFonts.ebGaramond(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Subject of letter',
                          labelStyle: TextStyle(color: VintageTheme.inkBlue),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: VintageTheme.inkBlue, width: 2),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a subject' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Content section (the ink pen sheet)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    decoration: VintageTheme.paperCardDecoration().copyWith(
                      // Custom parchment vertical lined graphics
                      image: const DecorationImage(
                        image: AssetImage('assets/parchment.png'), // Will fail gracefully if missing
                        fit: BoxFit.cover,
                        opacity: 0.05,
                      ),
                    ),
                    child: TextFormField(
                      controller: _contentController,
                      cursorColor: VintageTheme.inkBlue,
                      maxLines: null,
                      expands: true,
                      style: themeExtension.handwritingStyle,
                      decoration: InputDecoration(
                        hintText: 'My dearest friend...\n\nBegin your slow correspondence here with deliberate ink strokes.',
                        hintStyle: themeExtension.handwritingStyle.copyWith(color: VintageTheme.inkBlue.withOpacity(0.3)),
                        border: InputBorder.none,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Your letter has no words yet' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Delay Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: VintageTheme.paperCardDecoration(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dispatch Speed:',
                            style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                          ),
                          Text(
                            _getDelayLabel(),
                            style: GoogleFonts.ebGaramond(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: VintageTheme.waxSealRed,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _delaySeconds,
                        min: 10,
                        max: 86400 * 2, // 2 days max
                        divisions: 100,
                        activeColor: VintageTheme.inkBlue,
                        inactiveColor: VintageTheme.paperBorder,
                        thumbColor: VintageTheme.antiqueGold,
                        onChanged: (val) {
                          setState(() {
                            _delaySeconds = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Dispatch Button (Red Wax Stamp)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendLetter,
                    icon: const Icon(Icons.security, color: VintageTheme.parchmentLight),
                    label: Text(
                      'Apply Wax Seal & Dispatch',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VintageTheme.waxSealRed,
                      foregroundColor: VintageTheme.parchmentLight,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: VintageTheme.antiqueGold, width: 1.5),
                      ),
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

// Satisfying visual dialog simulating folding and wax stamping
class _WaxSealingDialog extends StatefulWidget {
  const _WaxSealingDialog();

  @override
  State<_WaxSealingDialog> createState() => _WaxSealingDialogState();
}

class _WaxSealingDialogState extends State<_WaxSealingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String _sealStatusText = 'Folding parchment paper...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.9, curve: Curves.bounceOut),
      ),
    );

    _animController.forward();

    // Sequence the text phases representing tactile physical assembly
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _sealStatusText = 'Sliding letter into envelope...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _sealStatusText = 'Melting crimson wax...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _sealStatusText = 'Stamping wax seal emblem!';
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: VintageTheme.paperCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Envelope outline
                      Container(
                        width: 140,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: VintageTheme.paperBorder, width: 2),
                          color: VintageTheme.parchmentLight,
                        ),
                        child: const Icon(Icons.mail_outline, size: 48, color: VintageTheme.paperBorder),
                      ),
                      // Wax Seal Stamp scale animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VintageTheme.waxSealRed,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.history_edu,
                              color: VintageTheme.parchmentLight,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                _sealStatusText,
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VintageTheme.inkBlue,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  color: VintageTheme.waxSealRed,
                  backgroundColor: VintageTheme.paperBorder,
                  minHeight: 2,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
