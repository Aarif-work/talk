import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'image_update_page.dart';
import 'journal_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _pinController = TextEditingController();
  bool _isSettingPin = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinExists();
  }

  Future<void> _checkIfPinExists() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('app_config').get();
      if (!doc.exists) {
        setState(() => _isSettingPin = true);
      } else {
        setState(() => _isSettingPin = false);
      }
    } catch (e) {
      debugPrint('Error checking PIN: $e');
    }
  }

  Future<void> _handleAuth() async {
    final enteredPin = _pinController.text.trim();
    if (enteredPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('settings').doc('app_config');
      final doc = await docRef.get();

      if (!doc.exists) {
        // App is actually in setup mode
        await docRef.set({'pin': enteredPin});
        await FirebaseAuth.instance.signInAnonymously();
      } else {
        // Check PIN from database
        final storedPin = doc.data()?['pin'];
        if (storedPin == enteredPin) {
          await FirebaseAuth.instance.signInAnonymously();
        } else {
          throw Exception('Incorrect PIN. Please try again.');
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is FirebaseAuthException) {
        if (e.code == 'admin-restricted-operation') {
          errorMessage = 'Please enable "Anonymous Authentication" in your Firebase console settings.';
        } else {
          errorMessage = e.message ?? 'Authentication failed';
        }
      } else if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _isSettingPin ? 'Setup PIN' : 'Enter PIN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A6572),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSettingPin ? 'Create a secure access code.' : 'Your private space is locked.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 16),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(letterSpacing: 8),
                    prefixIcon: null,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _handleAuth,
                  child: Text(
                    _isSettingPin ? 'Start Journey' : 'Unlock',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ImageUpdatePage(),
    const JournalPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), label: 'Gallery'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'Journal'),
            ],
          ),
        ),
      ),
    );
  }
}
