import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/api_providers.dart';
import '../../theme/vintage_theme.dart';
import '../letter_view.dart';

class OpenBoardTab extends ConsumerStatefulWidget {
  const OpenBoardTab({super.key});

  @override
  ConsumerState<OpenBoardTab> createState() => _OpenBoardTabState();
}

class _OpenBoardTabState extends ConsumerState<OpenBoardTab> {
  final TextEditingController _openBoardController = TextEditingController();
  String _searchedUnregName = '';

  @override
  void dispose() {
    _openBoardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Open board recipient lookup input
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _openBoardController,
                  cursorColor: VintageTheme.inkBlue,
                  decoration: InputDecoration(
                    hintText: 'Recipient\'s name...',
                    hintStyle: const TextStyle(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: VintageTheme.paperBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: VintageTheme.inkBlue, width: 1.5),
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _searchedUnregName = val.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VintageTheme.inkBlue,
                  foregroundColor: VintageTheme.parchmentLight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  setState(() {
                    _searchedUnregName = _openBoardController.text.trim();
                  });
                },
                child: const Icon(Icons.search, size: 20),
              )
            ],
          ),
        ),
        const Divider(height: 1, color: VintageTheme.paperBorder),
        Expanded(
          child: _searchedUnregName.isEmpty
              ? Center(
                  child: Text(
                    'Search for a name to view open letters left for them on this board.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 14),
                  ),
                )
              : Consumer(
                  builder: (context, ref, child) {
                    final openLettersFuture = ref.watch(openLettersProvider(_searchedUnregName));
                    return openLettersFuture.when(
                      data: (letters) {
                        if (letters.isEmpty) {
                          return Center(
                            child: Text(
                              'No open letters found for "$_searchedUnregName".',
                              style: GoogleFonts.ebGaramond(fontStyle: FontStyle.italic, fontSize: 14),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: letters.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final letter = letters[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  letter.subject,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                                ),
                                subtitle: const Text('Addressed publicly'),
                                trailing: const Icon(Icons.open_in_new, size: 16),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => LetterView(
                                        letterId: letter.id,
                                        senderName: 'Anonymous Courier',
                                        subject: letter.subject,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: VintageTheme.inkBlue)),
                      error: (e, _) => Center(child: Text('Courier failed: $e')),
                    );
                  },
                ),
        )
      ],
    );
  }
}
