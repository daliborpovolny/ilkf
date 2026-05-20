import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/api_providers.dart';
import '../theme/vintage_theme.dart';
import 'compose_view.dart';
import 'login_view.dart';
import 'widgets/address_book_tab.dart';
import 'widgets/inbox_tab.dart';
import 'widgets/open_board_tab.dart';
import 'widgets/outbox_tab.dart';
import 'widgets/pending_letters_stack.dart';

class DeskDashboard extends ConsumerWidget {
  const DeskDashboard({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(sessionProvider.notifier).state = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => _logout(context, ref),
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
                        const Expanded(flex: 3, child: PendingLettersStack()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildAddressBookCard()),
                      ],
                    )
                  : ListView(
                      children: [
                        _buildInboxOutboxCard(),
                        const SizedBox(height: 16),
                        const PendingLettersStack(),
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

  // --- COMPONENT: INBOX & OUTBOX WRAP ---
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
            const Expanded(
              child: TabBarView(
                children: [
                  InboxTab(),
                  OutboxTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENT: ADDRESS BOOK & PUBLIC BOARD WRAP ---
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
            const Expanded(
              child: TabBarView(
                children: [
                  AddressBookTab(),
                  OpenBoardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
