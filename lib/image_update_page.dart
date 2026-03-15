import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_drawer.dart';
import 'globals.dart';

class ImageUpdatePage extends StatefulWidget {
  const ImageUpdatePage({super.key});

  @override
  State<ImageUpdatePage> createState() => _ImageUpdatePageState();
}

class _ImageUpdatePageState extends State<ImageUpdatePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = p.basename(image.path);
      final String localPath = p.join(directory.path, fileName);
      
      await File(image.path).copy(localPath);

      await FirebaseFirestore.instance.collection('photos').add({
        'localPath': localPath,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'isLocal': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(source == ImageSource.camera ? '📸 Photo captured!' : '✨ Photo added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _viewFullScreen(String path, bool isLocal, String? url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: isLocal && path.isNotEmpty
                  ? Image.file(File(path))
                  : Image.network(url ?? '', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Globals.scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Our Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF8BAADD)),
            onPressed: () => _pickAndSaveImage(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF8BAADD)),
            onPressed: () => _pickAndSaveImage(ImageSource.gallery),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('photos')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final photos = snapshot.data!.docs;

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Your gallery is empty', style: TextStyle(color: Colors.grey)),
                  const Text('Tap icons to add from camera or gallery.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final doc = photos[index];
              final data = doc.data() as Map<String, dynamic>;
              final String? localPath = data['localPath'];
              final bool isLocal = data['isLocal'] ?? false;
              
              // Extract time from timestamp
              final timestamp = data['timestamp'] as Timestamp?;
              String timeStr = '--:--';
              if (timestamp != null) {
                final date = timestamp.toDate();
                final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
                final period = date.hour >= 12 ? 'PM' : 'AM';
                timeStr = "$hour:${date.minute.toString().padLeft(2, '0')} $period";
              }
              
              return Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _viewFullScreen(localPath ?? '', isLocal, data['url']),
                      onLongPress: () => _showReactionPicker(doc.id, data['reactions'] as Map<String, dynamic>? ?? {}),
                      child: Hero(
                        tag: doc.id,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[100],
                                child: localPath != null && File(localPath).existsSync()
                                    ? Image.file(File(localPath), fit: BoxFit.cover)
                                    : Image.network(
                                        data['url'] ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                              ),
                            ),
                            if (data['reactions'] != null && (data['reactions'] as Map).isNotEmpty)
                              Positioned(
                                bottom: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    (data['reactions'] as Map).keys.first.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showReactionPicker(String docId, Map<String, dynamic> currentReactions) {
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

                      // Single reaction logic:
                      final Map<String, dynamic> newReactions = {};
                      if (!currentReactions.containsKey(emoji)) {
                        newReactions[emoji] = userId;
                      }

                      await FirebaseFirestore.instance
                          .collection('photos')
                          .doc(docId)
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
}
