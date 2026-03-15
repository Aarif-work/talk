import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Our Space'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.favorite_rounded,
                size: 80,
                color: Color(0xFF8BAADD),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Our Space',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6572),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A private, secure, and beautiful corner for just the two of us. This app is designed to help us stay connected, share moments, and keep track of our thoughts through a shared journal and gallery.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Quick Reactions Guide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6572),
              ),
            ),
            const SizedBox(height: 16),
            _buildReactionInfo('❤️', 'Love'),
            _buildReactionInfo('🥺', 'Miss You'),
            _buildReactionInfo('🥺🥺', 'Missing you a lot'),
            _buildReactionInfo('😊', 'Happy'),
            _buildReactionInfo('😔', 'Sad'),
            _buildReactionInfo('😴', 'Tired'),
            _buildReactionInfo('👏', 'Good Job'),
            _buildReactionInfo('👍', 'Okay'),
            _buildReactionInfo('💪', 'Stay Strong'),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Privacy First',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6572),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Everything you share here is private and secured by your personal PIN. No one else has access to our memories.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionInfo(String emoji, String meaning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Text(
            meaning,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A6572),
            ),
          ),
        ],
      ),
    );
  }
}
