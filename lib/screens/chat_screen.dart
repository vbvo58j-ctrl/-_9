import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/bluetooth_chat_service.dart';

class ChatScreen extends StatefulWidget {
  final BluetoothChatService chatService;
  final String myUserId;
  final String deviceName;

  const ChatScreen({
    super.key,
    required this.chatService,
    required this.myUserId,
    required this.deviceName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<String>? _statusSubscription;

  String _status = 'جارٍ التحقق من الاتصال...';
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    _messageSubscription =
        widget.chatService.onMessageReceived.listen((message) {
      if (!mounted) return;

      setState(() {
        if (!_messages.any((item) => item.id == message.id)) {
          _messages.add(message);
        }
      });

      _scrollToBottom();
    });

    _statusSubscription =
        widget.chatService.onStatusChanged.listen((status) {
      if (!mounted) return;

      setState(() {
        _status = status;
      });
    });

    _status = widget.chatService.isConnected
        ? 'متصل'
        : 'غير متصل';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _sending) return;

    if (!widget.chatService.isConnected) {
      _showMessage('لا يوجد اتصال نشط بالجهاز الآخر.');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await widget.chatService.sendMessage(
        widget.myUserId,
        text,
      );

      if (!mounted) return;

      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        _showMessage('تعذر إرسال الرسالة: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deviceName,
              style: const TextStyle(fontSize: 17),
            ),
            Text(
              _status,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('ابدأ المحادثة بإرسال رسالة'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine =
                          message.senderId == widget.myUserId;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.78,
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFFDCF8C6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(message.text),
                              const SizedBox(height: 4),
                              Text(
                                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              color: const Color(0xFFECE5DD),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    color: const Color(0xFF075E54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}