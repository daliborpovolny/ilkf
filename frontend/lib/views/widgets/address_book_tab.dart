import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/api_providers.dart';
import '../../theme/vintage_theme.dart';
import '../compose_view.dart';

class AddressBookTab extends ConsumerWidget {
  const AddressBookTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortCriteria = ref.watch(contactSortProvider);
    final contactsFuture = ref.watch(contactsProvider);

    return Column(
      children: [
        // Clean Sorting Selector representing standard antique index card dividers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort Directory: ',
                  style: GoogleFonts.ebGaramond(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: sortCriteria,
                  dropdownColor: VintageTheme.parchmentLight,
                  style: GoogleFonts.ebGaramond(color: VintageTheme.inkBlue, fontSize: 14),
                  underline: Container(height: 1.5, color: VintageTheme.antiqueGold),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(contactSortProvider.notifier).state = val;
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'most_recent', child: Text('Most Recent')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest Interacted')),
                    DropdownMenuItem(value: 'pending_reply', child: Text('Pending My Reply')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: VintageTheme.paperBorder),
        Expanded(
          child: contactsFuture.when(
            data: (contacts) {
              if (contacts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No contacts yet. Correspond with someone by clicking the Write Letter button below!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 15),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final isPendingReply = contact.lastLetterSenderID == contact.contactId;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Text(
                            contact.contactUsername,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: VintageTheme.inkBlue, fontSize: 15),
                          ),
                          if (isPendingReply) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: VintageTheme.waxSealRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: VintageTheme.waxSealRed, width: 0.5),
                              ),
                              child: const Text(
                                'Pending Reply',
                                style: TextStyle(color: VintageTheme.waxSealRed, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        'Last interaction: ${contact.lastInteractionAt.month}/${contact.lastInteractionAt.day}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                        // Navigate to compose pre-filled
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ComposeView(initialRecipient: contact.contactUsername),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue)),
            error: (e, _) => Center(child: Text('Failed to read address book: $e')),
          ),
        ),
      ],
    );
  }
}
