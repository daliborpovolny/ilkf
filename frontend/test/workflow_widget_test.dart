import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilkf_frontend/main.dart';
import 'package:ilkf_frontend/providers/api_providers.dart';
import 'package:ilkf_frontend/models/models.dart';
import 'package:ilkf_frontend/views/login_view.dart';
import 'package:ilkf_frontend/views/desk_dashboard.dart';

// Robust Mock ApiService for pure, stable, and fast widget workflow verification
class MockApiService extends ApiService {
  MockApiService() : super('');

  bool registerCalled = false;
  bool forgotPasswordCalled = false;
  bool resetPasswordCalled = false;
  bool sendLetterCalled = false;

  @override
  Future<User> login(String usernameOrEmail, String password) async {
    if ((usernameOrEmail == 'alice' || usernameOrEmail == 'alice@ilkf.local') && password == 'alicepassword') {
      return User(
        id: 'alice-id-123',
        username: 'alice',
        email: 'alice@ilkf.local',
        createdAt: DateTime.now(),
      );
    }
    throw Exception('Invalid desk key');
  }

  @override
  Future<User> register(String username, String email, String password) async {
    registerCalled = true;
    return User(
      id: 'bob-id-456',
      username: username,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    forgotPasswordCalled = true;
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    resetPasswordCalled = true;
  }

  @override
  Future<List<Letter>> fetchInbox(String userId) async {
    return [
      Letter(
        id: 'letter-in-1',
        senderId: 'bob-id-456',
        senderUsername: 'bob',
        recipientId: 'alice-id-123',
        recipientUsername: 'alice',
        subject: 'A quiet evening',
        content: 'Dearest Alice, I hope this finds you well...',
        deliveryAt: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
        readAt: null,
      ),
    ];
  }

  @override
  Future<List<PendingLetter>> fetchPending(String userId) async {
    return [
      PendingLetter(
        id: 'letter-pending-1',
        senderId: 'bob-id-456',
        senderUsername: 'bob',
        recipientId: 'alice-id-123',
        subject: 'On my way',
        deliveryAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<Letter>> fetchOutbox(String userId) async {
    return [
      Letter(
        id: 'letter-out-1',
        senderId: 'alice-id-123',
        senderUsername: 'alice',
        recipientId: 'bob-id-456',
        recipientUsername: 'bob',
        subject: 'First thoughts',
        content: 'Dear Bob, just writing a quick word...',
        deliveryAt: DateTime.now().subtract(const Duration(minutes: 10)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        readAt: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
    ];
  }

  @override
  Future<List<Contact>> fetchContacts(String userId, String sortBy) async {
    return [
      Contact(
        contactId: 'bob-id-456',
        contactUsername: 'bob',
        lastInteractionAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<Letter> fetchLetterById(String userId, String letterId) async {
    return Letter(
      id: letterId,
      senderId: 'bob-id-456',
      senderUsername: 'bob',
      recipientId: 'alice-id-123',
      recipientUsername: 'alice',
      subject: 'A quiet evening',
      content: 'Dearest Alice, I hope this finds you well...',
      deliveryAt: DateTime.now().subtract(const Duration(minutes: 5)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
      readAt: DateTime.now(),
    );
  }
}

void main() {
  group('ILKF Frontend Widget Workflow Tests', () {
    late MockApiService mockApi;

    setUp(() {
      mockApi = MockApiService();
    });

    testWidgets('Complete Mock workflow: Login -> Navigate -> Dashboard Tab Switching -> Verify Elements', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pump App overriding apiServiceProvider with our Mock
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. VERIFY LOGIN FAILURE PATH
      final usernameField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Enter Username or Email...'
      );
      final passwordField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Enter Password Key...'
      );

      await tester.enterText(usernameField, 'wrong_user');
      await tester.enterText(passwordField, 'wrong_pass');
      await tester.pump();

      final openDeskButton = find.text('Open writing desk');
      await tester.tap(openDeskButton);
      await tester.pumpAndSettle();

      // Verify that error message is rendered
      expect(find.text('Invalid desk key'), findsOneWidget);

      // 2. VERIFY SUCCESSFUL LOGIN PATH
      await tester.enterText(usernameField, 'alice');
      await tester.enterText(passwordField, 'alicepassword');
      await tester.pump();
      await tester.tap(openDeskButton);
      await tester.pumpAndSettle();

      // We should now be redirected to the DeskDashboard
      expect(find.byType(DeskDashboard), findsOneWidget);
      expect(find.text('ALICE\'S WRITING DESK'), findsOneWidget);

      // 3. TAB WORKFLOW VERIFICATION (Inbox, Outbox, Address Book, Open Board)
      expect(find.text('Inbox (Letters)'), findsOneWidget);
      expect(find.text('Outbox (Sent)'), findsOneWidget);
      expect(find.text('Address Book'), findsOneWidget);
      expect(find.text('Open Board'), findsOneWidget);

      // Verify Inbox contains Alice's mock letter from Bob
      expect(find.text('A quiet evening'), findsOneWidget);
      expect(find.text('From: bob'), findsOneWidget);

      // Navigate to Outbox Tab
      await tester.tap(find.text('Outbox (Sent)'));
      await tester.pumpAndSettle();

      // Verify Outbox contains Alice's mock letter sent to Bob
      expect(find.text('First thoughts'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.startsWith('To: bob')),
        findsOneWidget,
      );

      // Navigate to Address Book
      await tester.tap(find.text('Address Book'));
      await tester.pumpAndSettle();

      // Verify Contact list shows Bob
      expect(find.text('bob'), findsOneWidget);

      // Navigate to Open Board
      await tester.tap(find.text('Open Board'));
      await tester.pumpAndSettle();

      // Go back to Inbox
      await tester.tap(find.text('Inbox (Letters)'));
      await tester.pumpAndSettle();

      // 4. VERIFY CARRIERS & TRANSIT CARRIERS STACK
      // Let's verify the Pending Carriers stack element is displayed on top
      expect(find.text('Letters in Transit'), findsOneWidget);
      expect(find.text('On my way'), findsOneWidget);
    });

    testWidgets('Verify Registration mock calling', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Register Desk
      await tester.tap(find.text('Register Desk'));
      await tester.pumpAndSettle();

      final regUserField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Enter Username...'
      );
      final regEmailField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Enter Email Address...'
      );
      final regPassField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Enter Password Key...'
      );

      await tester.enterText(regUserField, 'bob');
      await tester.enterText(regEmailField, 'bob@ilkf.local');
      await tester.enterText(regPassField, 'bobpassword');
      await tester.pump();

      await tester.tap(find.text('Unlock writing desk'));
      await tester.pumpAndSettle();

      // Registration registers user and auto logs them in
      expect(mockApi.registerCalled, isTrue);
      expect(find.byType(DeskDashboard), findsOneWidget);
      expect(find.text('BOB\'S WRITING DESK'), findsOneWidget);
    });
  });
}
