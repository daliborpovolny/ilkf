import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

final String _rawBaseUrl = const String.fromEnvironment('API_BASE_URL').trim();
final String baseUrl = _rawBaseUrl.isNotEmpty
    ? (_rawBaseUrl.endsWith('/api') || _rawBaseUrl.endsWith('/api/')
        ? _rawBaseUrl
        : (_rawBaseUrl.endsWith('/') ? '${_rawBaseUrl}api' : '$_rawBaseUrl/api'))
    : (kIsWeb
        ? (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1'
            ? 'http://localhost:8080/api'
            : "${Uri.base.scheme}://${Uri.base.host}${Uri.base.port != 80 && Uri.base.port != 443 && Uri.base.port != 0 ? ':${Uri.base.port}' : ''}/api")
        : 'http://localhost:8080/api');

// Current session provider (User? - null if not logged in)
final sessionProvider = StateProvider<User?>((ref) => null);

// Current contact list sort criteria provider
final contactSortProvider = StateProvider<String>((ref) => 'most_recent');

// API client helper class
class ApiService {
  final String _baseUrl;

  ApiService(this._baseUrl);

  Future<User> authenticate(String username) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Authentication failed');
    }
  }

  Future<User> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Registration failed');
    }
  }

  Future<User> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username_or_email': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Login failed');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to request password reset');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Password reset failed');
    }
  }

  Future<Letter> sendLetter({
    required String senderId,
    required String recipientUsername,
    required String recipientNameUnregistered,
    required String subject,
    required String content,
    required int delaySeconds,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/letters'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-ID': senderId,
      },
      body: jsonEncode({
        'recipient_username': recipientUsername,
        'recipient_name_unregistered': recipientNameUnregistered,
        'subject': subject,
        'content': content,
        'delivery_delay_seconds': delaySeconds,
      }),
    );

    if (response.statusCode == 201) {
      return Letter.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to send letter');
    }
  }

  Future<List<Letter>> fetchInbox(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/letters/inbox'),
      headers: {'X-User-ID': userId},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Letter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load inbox');
    }
  }

  Future<List<PendingLetter>> fetchPending(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/letters/pending'),
      headers: {'X-User-ID': userId},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PendingLetter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending letters');
    }
  }

  Future<List<Letter>> fetchOutbox(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/letters/outbox'),
      headers: {'X-User-ID': userId},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Letter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load outbox');
    }
  }

  Future<List<Contact>> fetchContacts(String userId, String sortBy) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts?sort=$sortBy'),
      headers: {'X-User-ID': userId},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Contact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load contacts');
    }
  }

  Future<Letter> fetchLetterById(String userId, String letterId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/letters/$letterId'),
      headers: {'X-User-ID': userId},
    );

    if (response.statusCode == 200) {
      return Letter.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to load letter');
    }
  }

  Future<List<Letter>> fetchOpenLetters(String unregisteredName) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/letters/open/$unregisteredName'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Letter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load open letters');
    }
  }
}

// Global API service instance provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService(baseUrl));

// Inbox letters list provider
final inboxProvider = FutureProvider.autoDispose<List<Letter>>((ref) async {
  final user = ref.watch(sessionProvider);
  if (user == null) return [];
  return ref.read(apiServiceProvider).fetchInbox(user.id);
});

// Pending incoming letters list provider
final pendingLettersProvider = FutureProvider.autoDispose<List<PendingLetter>>((ref) async {
  final user = ref.watch(sessionProvider);
  if (user == null) return [];
  return ref.read(apiServiceProvider).fetchPending(user.id);
});

// Outbox sent letters list provider
final outboxProvider = FutureProvider.autoDispose<List<Letter>>((ref) async {
  final user = ref.watch(sessionProvider);
  if (user == null) return [];
  return ref.read(apiServiceProvider).fetchOutbox(user.id);
});

// Contacts list provider (automatically refetches when sort criteria or session changes)
final contactsProvider = FutureProvider.autoDispose<List<Contact>>((ref) async {
  final user = ref.watch(sessionProvider);
  if (user == null) return [];
  final sortBy = ref.watch(contactSortProvider);
  return ref.read(apiServiceProvider).fetchContacts(user.id, sortBy);
});

// Letter detail provider (parameterized by letter ID)
final letterDetailProvider = FutureProvider.family.autoDispose<Letter, String>((ref, letterId) async {
  final user = ref.read(sessionProvider);
  if (user == null) throw Exception('User not authenticated');
  return ref.read(apiServiceProvider).fetchLetterById(user.id, letterId);
});

// Open board letters provider
final openLettersProvider = FutureProvider.family.autoDispose<List<Letter>, String>((ref, unregName) async {
  return ref.read(apiServiceProvider).fetchOpenLetters(unregName);
});
