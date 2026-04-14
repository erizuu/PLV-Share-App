import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? itemId;
  final String? itemName;
  final String? transactionId;
  final DateTime? transactionEndDate;
  final String status; // 'active', 'transaction_ended', 'archived'
  final String? otherUserName;
  final List<String> finishedBy; // Track which users confirmed finishing
  final String?
  lenderId; // ID of the user who accepted the request (item owner)

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.itemId,
    this.itemName,
    this.transactionId,
    this.transactionEndDate,
    required this.status,
    this.otherUserName,
    this.finishedBy = const [],
    this.lenderId,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      itemId: data['itemId'],
      itemName: data['itemName'],
      transactionId: data['transactionId'],
      transactionEndDate: (data['transactionEndDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      otherUserName: data['otherUserName'],
      finishedBy: List<String>.from(data['finishedBy'] ?? []),
      lenderId: data['lenderId'],
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystemMessage: data['isSystemMessage'] ?? false,
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
      'isRead': isRead,
    };
  }
}
