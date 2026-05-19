import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/api_providers.dart';
import '../theme/vintage_theme.dart';

class LetterView extends ConsumerWidget {
  final String letterId;
  final String senderName;
  final String subject;

  const LetterView({
    super.key,
    required this.letterId,
    required this.senderName,
    required this.subject,
  });

  String _formatDate(DateTime dt) {
    // Format to a elegant vintage style: "May 20th, 2026 at 01:13 AM"
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day;
    String suffix = 'th';
    if (day == 1 || day == 21 || day == 31) suffix = 'st';
    if (day == 2 || day == 22) suffix = 'nd';
    if (day == 3 || day == 23) suffix = 'rd';

    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';

    return '${months[dt.month - 1]} $day$suffix, ${dt.year} at $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letterDetail = ref.watch(letterDetailProvider(letterId));
    final themeExtension = Theme.of(context).extension<VintageWritingStyle>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
      ),
      body: letterDetail.when(
        data: (letter) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: VintageTheme.paperCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vintage Letter Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sender: $senderName',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VintageTheme.inkBlue,
                          ),
                        ),
                        Text(
                          _formatDate(letter.createdAt),
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: VintageTheme.inkBlue.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      letter.recipientNameUnregistered != null
                          ? 'Addressed to Open Board: ${letter.recipientNameUnregistered}'
                          : 'Addressed to: You',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        color: VintageTheme.inkBlue.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Divider representing paper tear/line
                    Container(
                      height: 1,
                      color: VintageTheme.paperBorder,
                    ),
                    const SizedBox(height: 24),
                    
                    // Subject line in large ink
                    Text(
                      letter.subject,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: VintageTheme.inkBlue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Letter Body in Elegant Handwriting Cursive
                    Text(
                      letter.content,
                      style: themeExtension.handwritingStyle,
                    ),
                    const SizedBox(height: 48),

                    // Satisfying Wax Seal imprint at bottom representing authenticity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Yours sincerely,',
                              style: themeExtension.handwritingStyle.copyWith(fontSize: 20),
                            ),
                            Text(
                              senderName,
                              style: themeExtension.handwritingStyle.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Embossed look wax seal
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VintageTheme.waxSealRed,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(1, 2),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.history_edu,
                              color: VintageTheme.parchmentLight,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: VintageTheme.inkBlue),
              SizedBox(height: 16),
              Text('Unfolding envelope, please wait...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: VintageTheme.paperCardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: VintageTheme.waxSealRed),
                  const SizedBox(height: 16),
                  Text(
                    'Courier access restricted!',
                    style: GoogleFonts.ebGaramond(fontSize: 20, fontWeight: FontWeight.bold, color: VintageTheme.waxSealRed),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString().replaceAll('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ebGaramond(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: VintageTheme.inkBlue),
                    child: const Text('Return to desk'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
