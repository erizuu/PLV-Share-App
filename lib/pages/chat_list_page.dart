import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/chat_service.dart';
import '../pages/chat_model.dart';
import 'chat_details_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _chatService.cleanupOldChats(); // Clean up old chats on load
    _checkAllChatsForOverdue(); // Check for overdue items
  }

  Future<void> _checkAllChatsForOverdue() async {
    try {
      // Get all chat rooms and check for overdue items
      // This will trigger notifications if any items are overdue
      final chatRooms = await _chatService.getChatRooms().first;
      for (final chatRoom in chatRooms) {
        if (chatRoom.transactionEndDate != null) {
          await _chatService.checkAndNotifyDeadline(chatRoom.id);
        }
      }
    } catch (e) {
      print('Error checking for overdue items: $e');
    }
  }

  String _getTimeAgo(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}w ago'; // weeks
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view chats')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFFFFF3E0),
            child: const Column(
              children: [
                Text(
                  '📦 RETURN DEADLINE: Check your borrowed items\' due dates',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Chats are cleared 7 days after the return deadline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Chat list
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: _chatService.getChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chats',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final chatRoom = snapshot.data![index];
                    final otherUserName = chatRoom.otherUserName ?? 'Unknown';
                    final daysLeft = _chatService.getDaysLeft(
                      chatRoom.transactionEndDate,
                    );
                    final isEnded = chatRoom.status == 'transaction_ended';
                    final isOverdue =
                        chatRoom.transactionEndDate != null &&
                        DateTime.now().isAfter(chatRoom.transactionEndDate!);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailPage(
                              chatRoomId: chatRoom.id,
                              otherUserName: otherUserName,
                              itemName: chatRoom.itemName ?? 'Item',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar with unread badge
                            Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2C3E50,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      otherUserName[0],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),
                                ),
                                // Unread badge
                                FutureBuilder<int>(
                                  future: _chatService.getUnreadMessageCount(
                                    chatRoom.id,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data! > 0) {
                                      return Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF6B4A),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            snapshot.data.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Chat info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        otherUserName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      Text(
                                        _getTimeAgo(chatRoom.lastMessageTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chatRoom.itemName ?? 'Unknown item',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (chatRoom.lastMessage != null)
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 8,
                                          ),
                                        ),
                                      if (chatRoom.lastMessage != null)
                                        const SizedBox(width: 4),
                                      if (chatRoom.lastMessage != null)
                                        Expanded(
                                          child: FutureBuilder<int>(
                                            future: _chatService
                                                .getUnreadMessageCount(
                                                  chatRoom.id,
                                                ),
                                            builder: (context, snapshot) {
                                              final hasUnread =
                                                  snapshot.hasData &&
                                                  snapshot.data! > 0;
                                              return Text(
                                                chatRoom.lastMessage!,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: hasUnread
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Status indicator with overdue badge
                                  if (isOverdue)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF5252,
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFFF5252,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        '⚠️ OVERDUE FOR RETURN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD32F2F),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isEnded
                                            ? Colors.grey.shade200
                                            : const Color(
                                                0xFFFF6B4A,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isEnded
                                            ? 'TRANSACTION ENDED'
                                            : '$daysLeft DAYS LEFT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isEnded
                                              ? Colors.grey.shade600
                                              : const Color(0xFFFF6B4A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
