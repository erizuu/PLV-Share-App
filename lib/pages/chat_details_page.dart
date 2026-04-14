import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../pages/chat_service.dart';
import '../pages/chat_model.dart';
import '../pages/profile_page.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String itemName;
  final String? otherUserId;

  const ChatDetailPage({
    super.key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.itemName,
    this.otherUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _hasAgreedToMeet = false;
  final ValueNotifier<DateTime> _timerNotifier = ValueNotifier(DateTime.now());
  late Timer _timerUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Initialize notifications
    _chatService.initializeNotifications();
    // Mark messages as read when opening chat
    _chatService.markMessagesAsRead(widget.chatRoomId);
    // Clean up old chats
    _chatService.cleanupOldChats();
    // Start timer to update ONLY the timer widget, not the whole page
    _timerUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timerNotifier.value = DateTime.now();
    });
    // Check if transaction has ended
    _checkAndUpdateTransactionStatus();
  }

  Future<void> _checkAndUpdateTransactionStatus() async {
    try {
      final chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
      if (chatRoom != null && chatRoom.transactionEndDate != null) {
        // Check if deadline has been reached
        await _chatService.checkAndNotifyDeadline(widget.chatRoomId);
      }
    } catch (e) {
      print('Error checking transaction status: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timerUpdateTimer.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String message = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      message: message,
    );

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleArrival() async {
    String message = 'I\'ve Arrived';
    await _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      message: message,
    );
  }

  void _handleWhereAreYou() async {
    String message = 'Where are you?';
    await _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      message: message,
    );
  }

  void _handleAgreeToMeet() {
    setState(() {
      _hasAgreedToMeet = !_hasAgreedToMeet;
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatTimeRemaining(DateTime endDate, DateTime now) {
    Duration remaining = endDate.add(const Duration(days: 7)).difference(now);

    if (remaining.isNegative) {
      return 'Chat will be deleted';
    }

    int days = remaining.inDays;
    int hours = remaining.inHours % 24;
    int minutes = remaining.inMinutes % 60;
    int seconds = remaining.inSeconds % 60;

    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} ${hours}h remaining';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} ${minutes}m remaining';
    } else if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''} remaining';
    } else {
      return '$seconds second${seconds > 1 ? 's' : ''} remaining';
    }
  }

  void _showSetDurationDialog() async {
    // Security check: only borrower can set duration
    final chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
    if (chatRoom?.lenderId == _currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the borrower can set the return duration'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay? selectedTime = TimeOfDay.now();

    // Show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B4A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      selectedDate = pickedDate;

      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFF6B4A),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF2C3E50),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        selectedTime = pickedTime;

        final transactionEndDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Update the chat room with the new transaction end date
        await _chatService.updateTransactionEndDate(
          widget.chatRoomId,
          transactionEndDate,
        );

        // Send system message
        await _chatService.sendMessage(
          chatRoomId: widget.chatRoomId,
          message:
              'Item return deadline set to ${DateFormat('MMM d, yyyy • h:mm a').format(transactionEndDate)}',
          isSystemMessage: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Return deadline updated'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            // Navigate to other user's profile with transaction context for rating
            if (widget.otherUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    userId: widget.otherUserId,
                    userName: widget.otherUserName,
                    ratingType:
                        null, // Will show both ratings since we don't know the context
                    transactionId: '',
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.itemName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Transaction timer and overdue status
          StreamBuilder<ChatRoom?>(
            stream: _chatService.watchChatRoom(widget.chatRoomId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final chatRoom = snapshot.data!;
                if (chatRoom.transactionEndDate != null &&
                    chatRoom.status == 'transaction_ended') {
                  final now = DateTime.now();
                  final endDate = chatRoom.transactionEndDate!;
                  final isOverdue = now.isAfter(endDate);
                  final timeRemaining = endDate
                      .add(const Duration(days: 7))
                      .difference(now);

                  // If time has expired, navigate back
                  if (timeRemaining.isNegative && mounted) {
                    Future.microtask(() {
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat has been archived and removed'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                    return const SizedBox.shrink();
                  }

                  // Show overdue banner if deadline passed
                  if (isOverdue) {
                    final overdueTime = now.difference(endDate);
                    final overdueDays = overdueTime.inDays;
                    final overdueHours = overdueTime.inHours % 24;

                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF5252).withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF5252,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warning_rounded,
                                  color: Color(0xFFFF5252),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '⚠️ ITEM OVERDUE FOR RETURN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFF5252),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Overdue by $overdueDays day${overdueDays != 1 ? 's' : ''} ${overdueHours}h',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.schedule,
                                color: const Color(0xFFFF5252).withOpacity(0.6),
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chat will be automatically cleared on ${DateFormat('MMM d, yyyy').format(endDate.add(const Duration(days: 7)))}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<ChatRoom?>(
                            stream: _chatService.watchChatRoom(
                              widget.chatRoomId,
                            ),
                            builder: (context, snapshotForButton) {
                              final chatRoom = snapshotForButton.data;
                              final hasCurrentUserFinished =
                                  chatRoom?.finishedBy.contains(
                                    _currentUser?.uid,
                                  ) ??
                                  false;

                              return ElevatedButton.icon(
                                onPressed: hasCurrentUserFinished
                                    ? null
                                    : () async {
                                        await _chatService
                                            .markTransactionFinished(
                                              widget.chatRoomId,
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Confirmed transaction completion',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.check_circle),
                                label: Text(
                                  hasCurrentUserFinished
                                      ? '✓ Transaction Finished'
                                      : 'Finish Transaction',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasCurrentUserFinished
                                      ? Colors.grey.shade400
                                      : const Color(0xFFFF5252),
                                  foregroundColor: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  // Show normal timer if not overdue
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B4A).withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B4A).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: Color(0xFFFF6B4A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Return Deadline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6B4A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ValueListenableBuilder<DateTime>(
                                    valueListenable: _timerNotifier,
                                    builder: (context, now, _) {
                                      return Text(
                                        _formatTimeRemaining(endDate, now),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.timer,
                              color: const Color(0xFFFF6B4A).withOpacity(0.6),
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: timeRemaining.isNegative
                                ? 0
                                : (7 -
                                          timeRemaining.inDays.toDouble().clamp(
                                            0,
                                            7,
                                          )) /
                                      7,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B4A),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Item must be returned by ${DateFormat('MMM d, yyyy • h:mm a').format(endDate)}. Chat will be cleared 7 days after this date.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Meeting info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B4A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF6B4A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meeting at: Student Center...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Student BLDG - 20m away',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.chatRoomId),
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
                          'Error loading messages',
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
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser?.uid;
                    final showAgreement =
                        message.message.contains('agreed to meet at') && !isMe;

                    if (showAgreement) {
                      // Extract location from message
                      String location = message.message.split('at: ').last;

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF6B4A).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Both have agreed to meet at:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2C3E50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF6B4A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    }

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Quick actions
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              label: "I've Arrived",
                              onTap: _handleArrival,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              label: "Where are you?",
                              onTap: _handleWhereAreYou,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _hasAgreedToMeet
                            ? const Color(0xFFFF6B4A)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.check,
                          color: _hasAgreedToMeet ? Colors.white : Colors.grey,
                        ),
                        onPressed: _handleAgreeToMeet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Duration button - only visible for borrower
                StreamBuilder<ChatRoom?>(
                  stream: _chatService.watchChatRoom(widget.chatRoomId),
                  builder: (context, roomSnapshot) {
                    final chatRoom = roomSnapshot.data;
                    final isBorrower = chatRoom?.lenderId != _currentUser?.uid;

                    if (!isBorrower) {
                      // Show informational message to lender
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The lender will set the return deadline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showSetDurationDialog,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Set Return Duration'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B4A),
                          side: const BorderSide(
                            color: Color(0xFFFF6B4A),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFFF6B4A),
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.otherUserName[0],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF6B4A) : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && !message.isSystemMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: !isMe && !message.isRead
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isMe ? Colors.white : const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B4A),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ),
      ),
    );
  }
}
