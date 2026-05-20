import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/api_providers.dart';
import '../../theme/vintage_theme.dart';

class PendingLettersStack extends ConsumerStatefulWidget {
  const PendingLettersStack({super.key});

  @override
  ConsumerState<PendingLettersStack> createState() => _PendingLettersStackState();
}

class _PendingLettersStackState extends ConsumerState<PendingLettersStack> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Schedule a local timer that ticks every 1 second to update the countdowns of pending letters!
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingFuture = ref.watch(pendingLettersProvider);

    return Container(
      height: 520,
      padding: const EdgeInsets.all(16),
      decoration: VintageTheme.paperCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Letters in Transit',
                  style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                ),
              ),
              IconButton(
                tooltip: 'Check mailbox watch',
                icon: const Icon(Icons.timer_outlined, color: VintageTheme.inkBlue),
                onPressed: () {
                  ref.invalidate(pendingLettersProvider);
                  ref.invalidate(inboxProvider);
                },
              ),
            ],
          ),
          const Divider(color: VintageTheme.paperBorder),
          Expanded(
            child: pendingFuture.when(
              data: (pendingList) {
                if (pendingList.isEmpty) {
                  return Center(
                    child: Text(
                      'No couriers are currently en route.',
                      style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 16),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: pendingList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = pendingList[index];
                    final remaining = item.timeRemaining;
                    
                    // Format time remaining readable
                    String remainingText = '';
                    if (remaining.isNegative) {
                      remainingText = 'Carrier arrived! Refresh to read.';
                    } else {
                      final h = remaining.inHours;
                      final m = remaining.inMinutes % 60;
                      final s = remaining.inSeconds % 60;
                      remainingText = 'Arriving in ${h > 0 ? '${h}h ' : ''}${m > 0 ? '${m}m ' : ''}${s}s';
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VintageTheme.parchmentLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: VintageTheme.paperBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.local_post_office, color: VintageTheme.waxSealRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  remainingText,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.ebGaramond(
                                    fontWeight: FontWeight.bold,
                                    color: VintageTheme.waxSealRed,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subject,
                            style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue)),
              error: (e, _) => Center(child: Text('Courier connection broken: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
