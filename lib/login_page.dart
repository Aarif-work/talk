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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Force sign out to ensure PIN is asked every time app starts
    await FirebaseAuth.instance.signOut();
    await _checkIfPinExists();
    if (mounted) setState(() => _isLoading = false);
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
        await docRef.set({'pin': enteredPin});
        await FirebaseAuth.instance.signInAnonymously();
      } else {
        final storedPin = doc.data()?['pin'];
        if (storedPin == enteredPin) {
          await FirebaseAuth.instance.signInAnonymously();
        } else {
          _pinController.clear();
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
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BAADD).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 64, color: Color(0xFF8BAADD)),
              ),
              const SizedBox(height: 32),
              Text(
                _isSettingPin ? 'Secure Your Space' : 'Welcome Back',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A6572)),
              ),
              const SizedBox(height: 12),
              Text(
                _isSettingPin ? 'Create a 4-digit PIN to begin.' : 'Enter your secret PIN to unlock.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              
              // Pin Display
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  readOnly: true, // Use a custom keypad or system keyboard
                  autofocus: true,
                  showCursor: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, letterSpacing: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A6572)),
                  decoration: const InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.grey, letterSpacing: 24),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Simple Grid Keypad
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  Widget content;
                  VoidCallback? action;

                  if (index < 9) {
                    final num = index + 1;
                    content = Text('$num', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600));
                    action = () {
                      if (_pinController.text.length < 4) {
                        setState(() => _pinController.text += num.toString());
                        if (_pinController.text.length == 4) _handleAuth();
                      }
                    };
                  } else if (index == 9) {
                    content = const Icon(Icons.backspace_outlined, color: Colors.redAccent);
                    action = () {
                      if (_pinController.text.isNotEmpty) {
                        setState(() => _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1));
                      }
                    };
                  } else if (index == 10) {
                    content = const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600));
                    action = () {
                      if (_pinController.text.length < 4) {
                        setState(() => _pinController.text += '0');
                        if (_pinController.text.length == 4) _handleAuth();
                      }
                    };
                  } else {
                    content = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32);
                    action = _handleAuth;
                  }

                  return InkWell(
                    onTap: action,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(child: content),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              if (_isSettingPin)
                TextButton(
                  onPressed: () => _pinController.clear(),
                  child: const Text('Clear', style: TextStyle(color: Colors.grey)),
                ),
            ],
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
