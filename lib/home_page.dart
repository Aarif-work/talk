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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Alert Priority',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A6572)),
            ),
            const SizedBox(height: 16),
            _buildAlertOption(
              context,
              stage: 1,
              title: "Stage 1: It's OK",
              subtitle: "Just checking in, no rush.",
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
            _buildAlertOption(
              context,
              stage: 2,
              title: "Stage 2: Important",
              subtitle: "Please open the app right now.",
              color: Colors.orange,
              icon: Icons.priority_high_rounded,
            ),
            _buildAlertOption(
              context,
              stage: 3,
              title: "Stage 3: Critical",
              subtitle: "Urgent! Need your attention immediately.",
              color: Colors.redAccent,
              icon: Icons.warning_rounded,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertOption(BuildContext context, {required int stage, required String title, required String subtitle, required Color color, required IconData icon}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        _sendAlert(stage);
      },
    );
  }

  void _sendAlert(int stage) async {
    String message = "";
    String body = "";
    Color snackColor = Colors.green;

    if (stage == 1) {
      message = "System Ping: OK";
      body = "Env: production. Connection status verified (200 OK).";
      snackColor = Colors.green;
    } else if (stage == 2) {
      message = "Sync Warning";
      body = "Local cache mismatch detected. Requesting manual refresh.";
      snackColor = Colors.orange;
    } else {
      message = "System Error: 503";
      body = "Severe latency in background processes. Immediate app check required.";
      snackColor = Colors.redAccent;
    }

    final now = DateTime.now();
    String period = now.hour >= 12 ? 'PM' : 'AM';
    int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    String minute = now.minute.toString().padLeft(2, '0');
    String timeStr = "$hour:$minute $period";

    await FirebaseFirestore.instance.collection('alerts').add({
      'message': message,
      'notes': 'Sent at $timeStr. $body',
      'timestamp': FieldValue.serverTimestamp(),
      'timeLabel': 'Today, $timeStr',
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'stage': stage,
    });

    await FirebaseFirestore.instance.collection('push_requests').add({
      'title': message, // Uses the tech-style titles
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert Sent: $body'),
          backgroundColor: snackColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          title: const Text('Flutter Testing', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          onLongPress: () => _showMessageOptions(
                            doc.id, 
                            data['text'] ?? '', 
                            data['userId'] ?? '', 
                            reactions
                          ),
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

  void _showMessageOptions(String messageId, String currentText, String originalUserId, Map<String, dynamic> currentReactions) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == originalUserId;
    final emojis = ['❤️', '🥺', '🥺🥺', '😊', '😔', '😴', '👏', '👍', '💪'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Reactions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: emojis.map((emoji) {
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) return;

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
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F9FC),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: emoji == '🥺🥺' ? 20 : 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (isOwner) ...[
              const Divider(height: 32, indent: 24, endIndent: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF8BAADD)),
                title: const Text('Edit Message', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(messageId, currentText);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(messageId);
                },
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String messageId, String currentText) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Type your message...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAADD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('messages').doc(messageId).update({'text': editController.text, 'isEdited': true});
                Navigator.pop(context);
              }
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone. Our secret space will lose this memory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('messages').doc(messageId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
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
