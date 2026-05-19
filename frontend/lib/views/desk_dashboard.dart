import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/api_providers.dart';
import '../theme/vintage_theme.dart';
import 'compose_view.dart';
import 'letter_view.dart';
import 'login_view.dart';

class DeskDashboard extends ConsumerStatefulWidget {
  const DeskDashboard({super.key});

  @override
  ConsumerState<DeskDashboard> createState() => _DeskDashboardState();
}

class _DeskDashboardState extends ConsumerState<DeskDashboard> {
  Timer? _timer;
  final TextEditingController _openBoardController = TextEditingController();
  String _searchedUnregName = '';

  @override
  void initState() {
    super.initState();
    // Schedule a timer that ticks every 1 second to update the countdowns of pending letters!
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _openBoardController.dispose();
    super.dispose();
  }

  void _logout() {
    ref.read(sessionProvider.notifier).state = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    if (user == null) {
      return const LoginView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.username.toUpperCase()}\'S WRITING DESK'),
        actions: [
          IconButton(
            tooltip: 'Leave Desk',
            icon: const Icon(Icons.key),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            
            // Build the main desk grid
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildInboxOutboxCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildPendingStackCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildAddressBookCard()),
                      ],
                    )
                  : ListView(
                      children: [
                        _buildInboxOutboxCard(),
                        const SizedBox(height: 16),
                        _buildPendingStackCard(),
                        const SizedBox(height: 16),
                        _buildAddressBookCard(),
                      ],
                    ),
            );
          },
        ),
      ),
      // Big Satisfying Floating Wax Seal for Composing
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ComposeView()),
          );
        },
        backgroundColor: VintageTheme.waxSealRed,
        foregroundColor: VintageTheme.parchmentLight,
        elevation: 6,
        icon: const Icon(Icons.history_edu),
        label: Text(
          'Write Letter',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // --- COMPONENT: INBOX & OUTBOX ---
  Widget _buildInboxOutboxCard() {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 520,
        decoration: VintageTheme.paperCardDecoration(),
        child: Column(
          children: [
            TabBar(
              labelColor: VintageTheme.inkBlue,
              unselectedLabelColor: VintageTheme.inkBlue.withOpacity(0.5),
              indicatorColor: VintageTheme.antiqueGold,
              labelStyle: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.inbox), text: 'Inbox (Letters)'),
                Tab(icon: Icon(Icons.outbox), text: 'Outbox (Sent)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInboxTab(),
                  _buildOutboxTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxTab() {
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
              return Card(
                child: ListTile(
                  title: Text(
                    letter.subject,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                  ),
                  subtitle: Text('From: ${letter.senderId == 'system' ? 'System' : 'Registered user'}'),
                  trailing: const Icon(Icons.drafts, color: VintageTheme.antiqueGold, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LetterView(
                          letterId: letter.id,
                          senderName: 'Friend',
                          subject: letter.subject,
                        ),
                      ),
                    );
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

  Widget _buildOutboxTab() {
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
              final recipientName = letter.recipientNameUnregistered ?? 'Registered User';
              return Card(
                child: ListTile(
                  title: Text(
                    letter.subject,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                  ),
                  subtitle: Text('To: $recipientName'),
                  trailing: Icon(
                    letter.recipientId != null ? Icons.markunread_mailbox : Icons.public,
                    color: VintageTheme.inkBlue.withOpacity(0.5),
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
                    );
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

  // --- COMPONENT: PENDING LETTERS STACK ---
  Widget _buildPendingStackCard() {
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
              Text(
                'Letters in Transit',
                style: GoogleFonts.ebGaramond(fontSize: 18, fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
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
                              Text(
                                remainingText,
                                style: GoogleFonts.ebGaramond(
                                  fontWeight: FontWeight.bold,
                                  color: VintageTheme.waxSealRed,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subject,
                            style: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold, color: VintageTheme.inkBlue),
                          ),
                          Text(
                            'Sender ID: ${item.senderId.substring(0, 8)}...',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          // Skeuomorphic timeline bar showing courier progression
                          const LinearProgressIndicator(
                            color: VintageTheme.waxSealRed,
                            backgroundColor: VintageTheme.paperBorder,
                            minHeight: 3,
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

  // --- COMPONENT: ADDRESS BOOK & PUBLIC BOARD ---
  Widget _buildAddressBookCard() {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 520,
        decoration: VintageTheme.paperCardDecoration(),
        child: Column(
          children: [
            TabBar(
              labelColor: VintageTheme.inkBlue,
              unselectedLabelColor: VintageTheme.inkBlue.withOpacity(0.5),
              indicatorColor: VintageTheme.antiqueGold,
              labelStyle: GoogleFonts.ebGaramond(fontSize: 16, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.contact_phone), text: 'Address Book'),
                Tab(icon: Icon(Icons.search), text: 'Open Board'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAddressBookTab(),
                  _buildOpenBoardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressBookTab() {
    final sortCriteria = ref.watch(contactSortProvider);
    final contactsFuture = ref.watch(contactsProvider);

    return Column(
      children: [
        // Clean Sorting Selector representing standard antique index card dividers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort Directory:',
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
                                color: VintageTheme.waxSealRed.withOpacity(0.1),
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

  Widget _buildOpenBoardTab() {
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
