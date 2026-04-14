import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../pages/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize Firebase Messaging and request notification permissions
  Future<void> initializeNotifications() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined or has not yet granted notification permission');
      }

      // Handle notification when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      });

      // Get the token for this device
      String? token = await _messaging.getToken();
      print('FCM Token: $token');

      // Store token in user document
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'fcmToken': token})
            .catchError((e) {
              print('Error updating FCM token: $e');
            });
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Get or create chat room for transaction
  Future<String> getOrCreateChatRoom({
    required String otherUserId,
    required String otherUserName,
    required String itemId,
    required String itemName,
    required String lenderId, // Explicitly specify who the lender is
    String? transactionId,
    DateTime? transactionEndDate,
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
        // If transaction end date is provided and chat room doesn't have it, update it
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (transactionEndDate != null &&
            (data['transactionEndDate'] == null ||
                data['status'] != 'transaction_ended')) {
          await doc.reference.update({
            'transactionEndDate': Timestamp.fromDate(transactionEndDate),
          });
        }
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
          'otherUserName': otherUserName,
          'transactionId': transactionId,
          'transactionEndDate': transactionEndDate != null
              ? Timestamp.fromDate(transactionEndDate)
              : null,
          'status': 'active',
          'lenderId': lenderId,
          'finishedBy': [],
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
          'isRead': false,
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
        .asyncMap((snapshot) async {
          List<ChatRoom> chatRooms = snapshot.docs
              .map((doc) => ChatRoom.fromFirestore(doc))
              .toList();

          // Enrich chat rooms with other user's name if missing
          for (int i = 0; i < chatRooms.length; i++) {
            if (chatRooms[i].otherUserName == null ||
                chatRooms[i].otherUserName!.isEmpty) {
              // Find the other user ID
              String otherUserId = chatRooms[i].participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isNotEmpty) {
                // Fetch the other user's name from users collection
                try {
                  DocumentSnapshot userDoc = await _firestore
                      .collection('users')
                      .doc(otherUserId)
                      .get();
                  if (userDoc.exists) {
                    Map<String, dynamic> userData =
                        userDoc.data() as Map<String, dynamic>;
                    String userName =
                        userData['fullName'] ??
                        userData['displayName'] ??
                        'Unknown';
                    // Update the chat room with the fetched name
                    chatRooms[i] = ChatRoom(
                      id: chatRooms[i].id,
                      participants: chatRooms[i].participants,
                      lastMessage: chatRooms[i].lastMessage,
                      lastMessageTime: chatRooms[i].lastMessageTime,
                      itemId: chatRooms[i].itemId,
                      itemName: chatRooms[i].itemName,
                      transactionId: chatRooms[i].transactionId,
                      transactionEndDate: chatRooms[i].transactionEndDate,
                      status: chatRooms[i].status,
                      otherUserName: userName,
                    );
                  }
                } catch (e) {
                  print('Error fetching user name: $e');
                }
              }
            }
          }

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

  // Mark transaction as ended and notify users about deadline
  Future<void> endTransaction(
    String chatRoomId,
    String transactionId, {
    DateTime? transactionEndDate,
  }) async {
    try {
      // Get chat room info
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return;

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      DateTime endDate =
          transactionEndDate ??
          (chatRoomData['transactionEndDate'] as Timestamp?)?.toDate() ??
          DateTime.now();
      String itemName = chatRoomData['itemName'] ?? 'Item';

      // Update status
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'status': 'transaction_ended',
        'transactionEndDate': Timestamp.fromDate(endDate),
      });

      // Send system message with deadline info
      final formattedDate =
          "${endDate.month}/${endDate.day}/${endDate.year} at ${endDate.hour}:${endDate.minute.toString().padLeft(2, '0')}";

      await sendMessage(
        chatRoomId: chatRoomId,
        message:
            '⏰ RETURN DEADLINE: $itemName must be returned by $formattedDate. Chat will be cleared 7 days after this date.',
        isSystemMessage: true,
      );

      // Send notifications to both users
      await sendNotificationToUsers(
        chatRoomId,
        '📦 Item Return Deadline',
        '$itemName must be returned by $formattedDate',
      );
    } catch (e) {
      print('Error ending transaction: $e');
    }
  }

  // Check if deadline has been reached and notify (returns true if deadline passed)
  Future<bool> checkAndNotifyDeadline(String chatRoomId) async {
    try {
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return false;

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      DateTime? transactionEndDate =
          (chatRoomData['transactionEndDate'] as Timestamp?)?.toDate();
      String status = chatRoomData['status'] ?? 'active';
      String itemName = chatRoomData['itemName'] ?? 'Item';

      if (transactionEndDate == null || status == 'archived') return false;

      // Check if deadline has passed
      if (DateTime.now().isAfter(transactionEndDate) &&
          status != 'transaction_ended') {
        await endTransaction(
          chatRoomId,
          '',
          transactionEndDate: transactionEndDate,
        );
        return true;
      }

      // Check if deadline just passed (within last hour) and send reminder
      if (status == 'transaction_ended' &&
          DateTime.now().isAfter(transactionEndDate) &&
          DateTime.now().isBefore(
            transactionEndDate.add(const Duration(hours: 1)),
          )) {
        // Check if reminder hasn't been sent yet
        QuerySnapshot reminderMessages = await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .where('message', isNotEqualTo: null)
            .get();

        bool reminderExists = reminderMessages.docs.any(
          (doc) =>
              (doc['message'] as String?)?.contains('⏰ RETURN DEADLINE') ??
              false,
        );

        if (!reminderExists) {
          await sendMessage(
            chatRoomId: chatRoomId,
            message:
                '⚠️ URGENT: $itemName should have been returned. Please arrange return immediately.',
            isSystemMessage: true,
          );

          await sendNotificationToUsers(
            chatRoomId,
            '🚨 Item Return Overdue',
            '$itemName was due for return. Please return it immediately.',
          );

          return true;
        }
      }

      return DateTime.now().isAfter(transactionEndDate);
    } catch (e) {
      print('Error checking deadline: $e');
      return false;
    }
  }

  // Check if item is overdue
  Future<bool> isItemOverdue(String chatRoomId) async {
    try {
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return false;

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      DateTime? transactionEndDate =
          (chatRoomData['transactionEndDate'] as Timestamp?)?.toDate();

      if (transactionEndDate == null) return false;

      return DateTime.now().isAfter(transactionEndDate);
    } catch (e) {
      print('Error checking if overdue: $e');
      return false;
    }
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

  // Mark messages as read for a chat room
  Future<void> markMessagesAsRead(String chatRoomId) async {
    String currentUserId = _auth.currentUser!.uid;

    // Get all unread messages from other users
    QuerySnapshot unreadMessages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    // Mark each message as read
    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get unread message count for a chat room
  Future<int> getUnreadMessageCount(String chatRoomId) async {
    String currentUserId = _auth.currentUser!.uid;

    QuerySnapshot unreadMessages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    return unreadMessages.docs.length;
  }

  // Update transaction end date in chat room
  Future<void> updateTransactionEndDate(
    String chatRoomId,
    DateTime endDate,
  ) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'transactionEndDate': Timestamp.fromDate(endDate),
    });
  }

  // Get chat room by ID
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!doc.exists) return null;

      return ChatRoom.fromFirestore(doc);
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  // Stream to monitor transaction end date for a specific chat room
  Stream<ChatRoom?> watchChatRoom(String chatRoomId) {
    return _firestore.collection('chatRooms').doc(chatRoomId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return ChatRoom.fromFirestore(doc);
    });
  }

  // Send notification to users
  Future<void> sendNotificationToUsers(
    String chatRoomId,
    String title,
    String body,
  ) async {
    try {
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return;

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(
        chatRoomData['participants'] ?? [],
      );

      // Send notification to each participant
      for (String userId in participants) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String? fcmToken = userData['fcmToken'] as String?;

          if (fcmToken != null) {
            // In a real implementation, you would use a backend service
            // to send FCM notifications. This is just a placeholder.
            print('Sending notification to $userId: $title - $body');
          }
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Mark transaction as finished by this user
  Future<void> markTransactionFinished(String chatRoomId) async {
    try {
      String currentUserId = _auth.currentUser!.uid;

      // Get current finishedBy list
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return;

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      List<String> finishedBy = List<String>.from(
        chatRoomData['finishedBy'] ?? [],
      );

      // Add current user if not already in list
      if (!finishedBy.contains(currentUserId)) {
        finishedBy.add(currentUserId);

        // Update finishedBy list
        await _firestore.collection('chatRooms').doc(chatRoomId).update({
          'finishedBy': finishedBy,
        });

        // Send system message
        String currentUserName = _auth.currentUser!.displayName ?? 'User';
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          currentUserName = userData['fullName'] ?? currentUserName;
        }

        await sendMessage(
          chatRoomId: chatRoomId,
          message: '$currentUserName has confirmed finish of transaction.',
          isSystemMessage: true,
        );

        // Check if both parties have finished
        await _checkBothPartiesFinished(chatRoomId);
      }
    } catch (e) {
      print('Error marking transaction finished: $e');
    }
  }

  // Check if both parties have marked transaction as finished
  Future<void> _checkBothPartiesFinished(String chatRoomId) async {
    try {
      DocumentSnapshot chatRoomDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return;

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      List<String> finishedBy = List<String>.from(
        chatRoomData['finishedBy'] ?? [],
      );
      List<String> participants = List<String>.from(
        chatRoomData['participants'] ?? [],
      );

      // If both participants have finished, set up 7-day auto cleanup
      if (finishedBy.length == participants.length &&
          participants.length == 2) {
        // Send system message to both
        await sendMessage(
          chatRoomId: chatRoomId,
          message:
              '✓ Transaction complete. This chat will be deleted in 7 days.',
          isSystemMessage: true,
        );

        // Send notification
        await sendNotificationToUsers(
          chatRoomId,
          'Transaction Completed',
          'Both parties have confirmed. Chat will be deleted in 7 days.',
        );
      }
    } catch (e) {
      print('Error checking if both parties finished: $e');
    }
  }
}
