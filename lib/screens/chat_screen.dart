import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final bool enableAnimations;
  final bool enableDecayTimer;

  const ChatScreen({
    super.key,
    required this.audioPlayer,
    this.enableAnimations = true,
    this.enableDecayTimer = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = ValueNotifier<List<Message>>([]);
  late AnimationController _flickerController;
  late AnimationController _sendButtonController;
  bool _shake = false;
  int _lastMessageCount = 0;
  OverlayEntry? _particleOverlay;
  int _tapCount = 0;
  Timer? _tapTimer;
  Timer? _decayTimer;

  @override
  void initState() {
    super.initState();
    print('DEBUG: ChatScreen - Starting initialization');

    // Play power-on sound
    print('DEBUG: Attempting to play power-on sound');
    widget.audioPlayer.play(AssetSource('sounds/power_on.wav'));

    // Load saved messages
    _loadMessages();

    // Initialize animations
    print('DEBUG: Initializing flicker animation');
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    if (widget.enableAnimations) {
      _flickerController.repeat(reverse: true);
    } else {
      _flickerController.value = 1.0; // Set to a stable value for tests
    }

    print('DEBUG: Initializing send button animation');
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.enableDecayTimer) {
      // Start message decay timer
      _decayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        _messages.value = _messages.value.where((msg) {
          final age = now.difference(msg.timestamp);
          return age.inMinutes < 5;
        }).toList();
        _saveMessages(); // Save after filtering
      });
    }

    print('DEBUG: ChatScreen - Initialization complete');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _flickerController.dispose();
    _sendButtonController.dispose();
    _particleOverlay?.remove();
    _tapTimer?.cancel();
    _decayTimer?.cancel();
    _messages.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('messages');
    if (messagesJson != null) {
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      _messages.value = messagesList.map((m) => Message.fromMap(m)).toList();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(_messages.value.map((m) => m.toMap()).toList());
    await prefs.setString('messages', messagesJson);
  }

  void _cleanupOldMessages() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _messages.value = _messages.value.where((msg) {
      return msg.timestamp.isAfter(cutoff);
    }).toList();
  }

  void _showParticleBurst() {
    _particleOverlay?.remove();
    _particleOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        right: 20,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          onEnd: () => _particleOverlay?.remove(),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red[900],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red[900]!.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_particleOverlay!);
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final message = Message(
        text: _messageController.text,
        sender: Provider.of<UserModel>(context, listen: false).username ?? 'Unknown',
        timestamp: DateTime.now(),
      );

      _messages.value = [..._messages.value, message];
      await _saveMessages();
      _messageController.clear();

      // Play sound effect
      widget.audioPlayer.play(AssetSource('sounds/plasma_rifle.wav'));

      // Trigger send button animation
      if (widget.enableAnimations) {
        _sendButtonController.forward().then((_) => _sendButtonController.reverse());
      }

      // Scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getDecayTime(int timestamp) {
    final hoursLeft =
        24 - (DateTime.now().millisecondsSinceEpoch - timestamp) / 3600000;
    if (hoursLeft <= 0) return 'Decayed';
    if (hoursLeft < 1) return 'Decays soon';
    return 'Decays in ${hoursLeft.round()}h';
  }

  Color _getDecayColor(int timestamp) {
    final hoursLeft =
        24 - (DateTime.now().millisecondsSinceEpoch - timestamp) / 3600000;
    if (hoursLeft <= 0) return Colors.grey;
    if (hoursLeft < 1) return Colors.yellow;
    return Colors.grey[400]!;
  }

  Future<void> _logout() async {
    await widget.audioPlayer.play(AssetSource('sounds/door_slam.wav'));
    if (mounted) {
      context.read<UserModel>().logout();
      Navigator.of(context).pop();
    }
  }

  void _handleAppBarTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 1), () => _tapCount = 0);

    if (_tapCount == 3) {
      print('DEBUG: Triple tap detected - playing grunt sound');
      widget.audioPlayer
          .play(AssetSource('sounds/doom_grunt.wav'), volume: 0.3)
          .then((_) => print('DEBUG: Grunt sound played successfully'))
          .catchError(
              (error) => print('DEBUG: Error playing grunt sound: $error'));
      _tapCount = 0;
    }
  }

  void _simulateIncomingMessage() {
    final newMessage = Message(
      text: 'Incoming test message from the wastes!',
      sender: 'WastelandBot',
      timestamp: DateTime.now(),
    );
    _messages.value = [..._messages.value, newMessage];
    widget.audioPlayer.play(AssetSource('sounds/metal_clang.wav'));
  }

  void _addDebugMessage() {
    final newMessage = Message(
      text: 'Debug message from the wasteland!',
      sender: 'WastelandBot',
      timestamp: DateTime.now(),
    );
    _messages.value = [..._messages.value, newMessage];
    _saveMessages();
    widget.audioPlayer.play(AssetSource('sounds/metal_clang.wav'));
  }

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<UserModel>(context).username;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: GestureDetector(
          onTap: _handleAppBarTap,
          child: FadeTransition(
            opacity: _flickerController,
            child: const Text(
              'SafeChat: Wasteland v1.0.0',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.green),
            onPressed: _addDebugMessage,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.green),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<Message>>(
              valueListenable: _messages,
              builder: (context, messages, child) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet...',
                      style: TextStyle(color: Colors.green),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final decayTime = message.timestamp
                        .add(const Duration(minutes: 5))
                        .difference(DateTime.now());
                    final isMe = message.sender == username;

                    return ListTile(
                      title: Text(
                        message.text,
                        style: const TextStyle(color: Colors.green),
                      ),
                      subtitle: Text(
                        '${message.sender} - Decays in ${decayTime.inMinutes}m ${decayTime.inSeconds % 60}s',
                        style: TextStyle(
                          color: decayTime.inMinutes > 0
                              ? Colors.grey
                              : Colors.red,
                        ),
                      ),
                      tileColor: isMe ? Colors.green.withAlpha(25) : null,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border.all(
                color: Colors.brown[900]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(77),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Transmit message...',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (_) => widget.audioPlayer.play(
                      AssetSource('sounds/typewriter_clack.wav'),
                      volume: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _sendButtonController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.red),
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
}
