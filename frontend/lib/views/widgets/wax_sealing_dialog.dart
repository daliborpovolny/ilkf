import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/vintage_theme.dart';

class WaxSealingDialog extends StatefulWidget {
  const WaxSealingDialog({super.key});

  @override
  State<WaxSealingDialog> createState() => _WaxSealingDialogState();
}

class _WaxSealingDialogState extends State<WaxSealingDialog> with SingleTickerProviderStateMixin {
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
