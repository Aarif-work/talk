import 'dart:async';
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
  
  void _showJournalList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Journal Entries',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A6572)),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.book_outlined, color: Color(0xFF8BAADD)),
                      title: Text(data['date'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        (data['content'] as String).length > 30 
                          ? '${(data['content'] as String).substring(0, 30)}...' 
                          : data['content'] ?? 'Empty entry',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('journals')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Scaffold(body: Center(child: Text('Something went wrong')));
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final docs = snapshot.data!.docs;
        final totalEntries = docs.length;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Journal Entries', style: TextStyle(color: Color(0xFF4A6572), fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF8BAADD)),
                onPressed: () => _showJournalList(context, docs),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: docs.isEmpty
                ? Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('journals').add({
                          'date': 'Today',
                          'content': '',
                          'seen': false,
                          'timestamp': FieldValue.serverTimestamp(),
                          'userId': FirebaseAuth.instance.currentUser?.uid,
                        });
                      },
                      child: const Text('Start your first journal entry'),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: totalEntries,
                    itemBuilder: (context, index) {
                      return JournalEntryView(doc: docs[index], index: index);
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
      },
    );
  }
}

class JournalEntryView extends StatefulWidget {
  final DocumentSnapshot doc;
  final int index;
  const JournalEntryView({super.key, required this.doc, required this.index});

  @override
  State<JournalEntryView> createState() => _JournalEntryViewState();
}

class _JournalEntryViewState extends State<JournalEntryView> with WidgetsBindingObserver {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final data = widget.doc.data() as Map<String, dynamic>;
    _controller = TextEditingController(text: data['content'] ?? '');
  }

  @override
  void didUpdateWidget(JournalEntryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id) {
      // Swiping to a new entry - save the OLD one immediately before switching
      final oldData = oldWidget.doc.data() as Map<String, dynamic>?;
      if (oldData != null && _controller.text != (oldData['content'] ?? '')) {
        _saveContent(_controller.text);
      }
      
      final data = widget.doc.data() as Map<String, dynamic>;
      _controller.text = data['content'] ?? '';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save when app goes to background or is closed
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_debounce?.isActive ?? false) {
        _debounce!.cancel();
        _saveContent(_controller.text);
      }
    }
  }

  @override
  void dispose() {
    // Final save attempt when the widget is destroyed (page switched)
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _saveContent(_controller.text);
    }
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () => _saveContent(text));
  }

  Future<void> _saveContent(String text) async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('journals')
          .doc(widget.doc.id)
          .update({'content': text});
    } catch (e) {
      debugPrint('Save error: $e');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.doc.data() as Map<String, dynamic>;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['date'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6572),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isSaving ? 'Syncing...' : 'All changes saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isSaving ? Colors.orange : Colors.green[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('journals')
                      .doc(widget.doc.id)
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
              controller: _controller,
              maxLines: null,
              expands: true,
              onChanged: _onChanged,
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
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_left_rounded, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                widget.index == 0 ? 'Swipe for past entries' : 'Swipe to return',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          )
        ],
      ),
    );
  }
}
