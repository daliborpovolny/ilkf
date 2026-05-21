import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/api_providers.dart';
import '../../theme/vintage_theme.dart';
import '../letter_view.dart';

class InboxTab extends ConsumerWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxFuture = ref.watch(inboxProvider);

    return inboxFuture.when(
      data: (letters) {
        if (letters.isEmpty) {
          return Center(
            child: Text(
              'Your letter slot is currently empty.',
              style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 16),
            ),
          );
        }
        return RefreshIndicator(
          color: VintageTheme.inkBlue,
          onRefresh: () => ref.refresh(inboxProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: letters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final letter = letters[index];
              final isUnread = letter.readAt == null;

              return Card(
                color: isUnread ? VintageTheme.parchmentLight : VintageTheme.parchmentLight.withValues(alpha: 0.85),
                child: ListTile(
                  title: Row(
                    children: [
                      if (isUnread) ...[
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VintageTheme.waxSealRed,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          letter.subject,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                            color: isUnread ? VintageTheme.inkBlue : VintageTheme.inkBlue.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'From: ${letter.senderUsername.isNotEmpty ? letter.senderUsername : (letter.senderId == 'system' ? 'System' : 'Unknown')}',
                    style: TextStyle(
                      color: isUnread ? VintageTheme.inkBlue.withValues(alpha: 0.8) : VintageTheme.inkBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Icon(
                    isUnread ? Icons.mail : Icons.drafts,
                    color: isUnread ? VintageTheme.waxSealRed : VintageTheme.antiqueGold,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LetterView(
                          letterId: letter.id,
                          senderName: letter.senderUsername.isNotEmpty ? letter.senderUsername : 'Friend',
                          subject: letter.subject,
                        ),
                      ),
                    ).then((_) {
                      ref.invalidate(inboxProvider);
                    });
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue)),
      error: (e, _) => Center(child: Text('Courier got lost: $e')),
    );
  }
}
