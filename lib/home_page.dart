import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alert_logs_page.dart';
import 'app_drawer.dart';
import 'globals.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    final token = await FirebaseMessaging.instance.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('user_tokens').doc(user.uid).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showEmergencyAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Send Emergency Alert?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6572),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will notify her immediately that you might need urgent attention.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        String period = now.hour >= 12 ? 'PM' : 'AM';
                        int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
                        String minute = now.minute.toString().padLeft(2, '0');
                        String timeStr = "$hour:$minute $period";

                        await FirebaseFirestore.instance.collection('alerts').add({
                          'message': 'Emergency Alert Sent',
                          'notes': 'Sent at $timeStr from the space.',
                          'timestamp': FieldValue.serverTimestamp(),
                          'timeLabel': 'Today, $timeStr',
                          'userId': FirebaseAuth.instance.currentUser?.uid,
                        });

                        // Triggering a 'push_request' collection that a Cloud Function can listen to
                        await FirebaseFirestore.instance.collection('push_requests').add({
                          'title': '🚨 Emergency Alert!',
                          'body': 'Someone needs your attention in Our Space!',
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emergency Alert & Notification Sent!'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Send now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Globals.scaffoldKey.currentState?.openDrawer(),
          ),
          title: const Text('Our Space', style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded),
              color: Colors.grey[600],
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlertLogsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.error_outline),
              color: Colors.redAccent,
              onPressed: () => _showEmergencyAlert(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'HE'),
              Tab(text: 'SHE'),
            ],
            labelColor: Color(0xFF4A6572),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF8BAADD),
          ),
        ),
        body: const TabBarView(
          children: [
            ChatView(sender: 'HE'),
            ChatView(sender: 'SHE'),
          ],
        ),
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  final String sender;
  const ChatView({super.key, required this.sender});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHe = widget.sender == 'HE';
    final bubbleColor = isHe ? const Color(0xFFE3EDF7) : const Color(0xFFFBE4E4);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('sender', isEqualTo: widget.sender)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final doc = messages[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
                  
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onLongPress: () => _showReactionPicker(doc.id, reactions),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    color: isHe ? const Color(0xFF4A6572) : const Color(0xFF905A5A),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (reactions.isNotEmpty)
                                Positioned(
                                  bottom: -8,
                                  right: isHe ? 12 : null,
                                  left: isHe ? null : 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: reactions.entries.map((e) {
                                        return Text(e.key, style: const TextStyle(fontSize: 12));
                                      }).toList(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16, top: 2),
                          child: Text(
                            data['time'] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add to ${widget.sender} space...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (val) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: theme.primaryColor,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  void _showReactionPicker(String messageId, Map<String, dynamic> currentReactions) {
    final emojis = ['❤️', '🥺', '🥺🥺', '😊', '😔', '😴', '👏', '👍', '💪'];
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) {
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) return;

                      // "Only one emoji react" logic:
                      final Map<String, dynamic> newReactions = {};
                      
                      if (!currentReactions.containsKey(emoji)) {
                        newReactions[emoji] = userId;
                      }

                      await FirebaseFirestore.instance
                          .collection('messages')
                          .doc(messageId)
                          .update({'reactions': newReactions});
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        emoji, 
                        style: TextStyle(
                          fontSize: emoji == '🥺🥺' ? 20 : 24
                        )
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final text = _controller.text;
      _controller.clear();

      final now = DateTime.now();
      String period = now.hour >= 12 ? 'PM' : 'AM';
      int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      String minute = now.minute.toString().padLeft(2, '0');
      String timeStr = "$hour:$minute $period";

      await FirebaseFirestore.instance.collection('messages').add({
        'sender': widget.sender,
        'text': text,
        'time': timeStr,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'reactions': {},
      });
    }
  }
}
