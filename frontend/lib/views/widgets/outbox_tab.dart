import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/api_providers.dart';
import '../../theme/vintage_theme.dart';
import '../letter_view.dart';

class OutboxTab extends ConsumerWidget {
  const OutboxTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outboxFuture = ref.watch(outboxProvider);

    return outboxFuture.when(
      data: (letters) {
        if (letters.isEmpty) {
          return Center(
            child: Text(
              'You haven\'t sent any letters yet.',
              style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 16),
            ),
          );
        }
        return RefreshIndicator(
          color: VintageTheme.inkBlue,
          onRefresh: () => ref.refresh(outboxProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: letters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final letter = letters[index];
              final recipientName = letter.recipientUsername != null && letter.recipientUsername!.isNotEmpty
                  ? letter.recipientUsername!
                  : (letter.recipientNameUnregistered ?? 'Anonymous');
              
              final isPublic = letter.recipientId == null;
              final isInTransit = letter.deliveryAt.isAfter(DateTime.now());
              final isRead = letter.readAt != null;
              
              String subtitleText = 'To: $recipientName';
              IconData trailingIcon = Icons.markunread_mailbox;
              Color iconColor = VintageTheme.inkBlue.withValues(alpha: 0.5);

              if (isPublic) {
                subtitleText = 'Public Board: $recipientName';
                trailingIcon = Icons.public;
                iconColor = VintageTheme.antiqueGold;
              } else if (isInTransit) {
                subtitleText = 'To: $recipientName • In Transit';
                trailingIcon = Icons.hourglass_top;
                iconColor = Colors.grey;
              } else if (isRead) {
                subtitleText = 'To: $recipientName • Read';
                trailingIcon = Icons.mark_email_read;
                iconColor = VintageTheme.inkBlue;
              } else {
                subtitleText = 'To: $recipientName • Delivered (Unread)';
                trailingIcon = Icons.markunread_mailbox;
                iconColor = VintageTheme.waxSealRed;
              }

              return Card(
                child: ListTile(
                  title: Text(
                    letter.subject,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                  ),
                  subtitle: Text(
                    subtitleText,
                    style: TextStyle(
                      color: isInTransit ? Colors.grey : VintageTheme.inkBlue.withValues(alpha: 0.6),
                      fontStyle: isInTransit ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  trailing: Icon(
                    trailingIcon,
                    color: iconColor,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LetterView(
                          letterId: letter.id,
                          senderName: 'You',
                          subject: letter.subject,
                        ),
                      ),
                    ).then((_) {
                      ref.invalidate(outboxProvider);
                    });
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue)),
      error: (e, _) => Center(child: Text('Error loading sent mail: $e')),
    );
  }
}
