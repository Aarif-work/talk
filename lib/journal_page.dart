import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final PageController _pageController = PageController();
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('journals')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            // If empty, add a default 'Today' entry
            if (docs.isEmpty) {
              return Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('journals').add({
                      'date': 'Today',
                      'content': '',
                      'seen': false,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  },
                  child: const Text('Start your first journal entry'),
                ),
              );
            }

            return PageView.builder(
              controller: _pageController,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final entry = doc.data() as Map<String, dynamic>;
                
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A6572),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('journals')
                                  .doc(doc.id)
                                  .update({'seen': !(entry['seen'] ?? false)});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: (entry['seen'] ?? false) ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    (entry['seen'] ?? false) ? Icons.check_circle : Icons.check_circle_outline,
                                    color: (entry['seen'] ?? false) ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (entry['seen'] ?? false) ? 'Seen ✓' : 'Mark Seen',
                                    style: TextStyle(
                                      color: (entry['seen'] ?? false) ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: TextField(
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts here...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.6,
                            color: Color(0xFF4A6572),
                          ),
                          controller: TextEditingController(text: entry['content'] ?? '')
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: (entry['content'] ?? '').length),
                            ),
                          onChanged: (text) {
                            // In a real app, you'd debounce this or use a save button.
                            // For this UI mockup, we'll update Firestore on change.
                            FirebaseFirestore.instance
                                .collection('journals')
                                .doc(doc.id)
                                .update({'content': text});
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_left_rounded, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            index == 0 ? 'Swipe for past entries' : 'Swipe to return',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now();
          final dateStr = "${now.day}/${now.month}/${now.year}";
          await FirebaseFirestore.instance.collection('journals').add({
            'date': dateStr,
            'content': '',
            'seen': false,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': FirebaseAuth.instance.currentUser?.uid,
          });
        },
        child: const Icon(Icons.edit_note_rounded, color: Colors.white),
      ),
    );
  }
}
