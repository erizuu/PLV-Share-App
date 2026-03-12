import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create chat room for transaction
  Future<String> getOrCreateChatRoom({
    required String otherUserId,
    required String otherUserName,
    required String itemId,
    required String itemName,
    String? transactionId,
  }) async {
    String currentUserId = _auth.currentUser!.uid;

    // Check if chat room already exists
    QuerySnapshot existingRooms = await _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingRooms.docs) {
      List<dynamic> participants = doc['participants'];
      if (participants.contains(otherUserId) && doc['itemId'] == itemId) {
        return doc.id;
      }
    }

    // Create new chat room
    DocumentReference chatRoomRef = await _firestore
        .collection('chatRooms')
        .add({
          'participants': [currentUserId, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat started',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'itemId': itemId,
          'itemName': itemName,
          'transactionId': transactionId,
          'transactionEndDate': null,
          'status': 'active',
        });

    return chatRoomRef.id;
  }

  // Send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    bool isSystemMessage = false,
  }) async {
    String currentUserId = _auth.currentUser!.uid;
    String currentUserName = _auth.currentUser!.displayName ?? 'User';

    // Get user data for name
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      currentUserName = userData['fullName'] ?? currentUserName;
    }

    // Add message
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'senderName': currentUserName,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isSystemMessage': isSystemMessage,
        });

    // Update last message in chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream for a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  // Get chat rooms for current user
  Stream<List<ChatRoom>> getChatRooms() {
    String currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          List<ChatRoom> chatRooms = snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();

          // Sort by lastMessageTime in descending order (newest first)
          chatRooms.sort((a, b) {
            final aTime =
                a.lastMessageTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
            final bTime =
                b.lastMessageTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          return chatRooms;
        });
  }

  // Mark transaction as ended
  Future<void> endTransaction(String chatRoomId, String transactionId) async {
    DateTime endDate = DateTime.now();

    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'status': 'transaction_ended',
      'transactionEndDate': Timestamp.fromDate(endDate),
    });

    // Send system message
    await sendMessage(
      chatRoomId: chatRoomId,
      message: 'Transaction has ended. Chat will be cleared in 7 days.',
      isSystemMessage: true,
    );
  }

  // Get days left before chat is cleared
  int getDaysLeft(DateTime? endDate) {
    if (endDate == null) return 7;

    DateTime clearDate = endDate.add(const Duration(days: 7));
    return clearDate.difference(DateTime.now()).inDays;
  }

  // Auto-cleanup function (run this periodically or when opening chat)
  Future<void> cleanupOldChats() async {
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    QuerySnapshot oldChats = await _firestore
        .collection('chatRooms')
        .where('status', isEqualTo: 'transaction_ended')
        .where(
          'transactionEndDate',
          isLessThan: Timestamp.fromDate(sevenDaysAgo),
        )
        .get();

    for (var doc in oldChats.docs) {
      // Delete messages subcollection
      QuerySnapshot messages = await doc.reference.collection('messages').get();
      for (var msg in messages.docs) {
        await msg.reference.delete();
      }

      // Archive or delete chat room
      await doc.reference.update({'status': 'archived'});
    }
  }
}
