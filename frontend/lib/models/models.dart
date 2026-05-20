class User {
  final String id;
  final String username;
  final String? email;
  final DateTime createdAt;

  User({required this.id, required this.username, this.email, required this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Letter {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? recipientId;
  final String? recipientUsername;
  final String? recipientNameUnregistered;
  final String subject;
  final String content;
  final DateTime deliveryAt;
  final DateTime createdAt;
  final DateTime? readAt;

  Letter({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.recipientId,
    this.recipientUsername,
    this.recipientNameUnregistered,
    required this.subject,
    required this.content,
    required this.deliveryAt,
    required this.createdAt,
    this.readAt,
  });

  factory Letter.fromJson(Map<String, dynamic> json) {
    return Letter(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderUsername: json['sender_username'] ?? '',
      recipientId: json['recipient_id'],
      recipientUsername: json['recipient_username'],
      recipientNameUnregistered: json['recipient_name_unregistered'],
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      deliveryAt: DateTime.parse(json['delivery_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  bool get isSenderUnregistered => recipientId == null && recipientNameUnregistered != null;
}

class PendingLetter {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? recipientId;
  final String subject;
  final DateTime deliveryAt;
  final DateTime createdAt;

  PendingLetter({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.recipientId,
    required this.subject,
    required this.deliveryAt,
    required this.createdAt,
  });

  factory PendingLetter.fromJson(Map<String, dynamic> json) {
    return PendingLetter(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderUsername: json['sender_username'] ?? '',
      recipientId: json['recipient_id'],
      subject: json['subject'] ?? '',
      deliveryAt: DateTime.parse(json['delivery_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Returns remaining delivery time
  Duration get timeRemaining => deliveryAt.difference(DateTime.now());
  bool get isDelivered => timeRemaining.isNegative;
}

class Contact {
  final String contactId;
  final String contactUsername;
  final DateTime lastInteractionAt;
  final String? lastLetterID;
  final String? lastLetterSenderID;
  final DateTime? lastLetterDeliveryAt;
  final DateTime? lastLetterCreatedAt;

  Contact({
    required this.contactId,
    required this.contactUsername,
    required this.lastInteractionAt,
    this.lastLetterID,
    this.lastLetterSenderID,
    this.lastLetterDeliveryAt,
    this.lastLetterCreatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      contactId: json['contact_id'] ?? '',
      contactUsername: json['contact_username'] ?? '',
      lastInteractionAt: DateTime.parse(json['last_interaction_at'] ?? DateTime.now().toIso8601String()),
      lastLetterID: json['last_letter_id'],
      lastLetterSenderID: json['last_letter_sender_id'],
      lastLetterDeliveryAt: json['last_letter_delivery_at'] != null
          ? DateTime.parse(json['last_letter_delivery_at'])
          : null,
      lastLetterCreatedAt: json['last_letter_created_at'] != null
          ? DateTime.parse(json['last_letter_created_at'])
          : null,
    );
  }
}
