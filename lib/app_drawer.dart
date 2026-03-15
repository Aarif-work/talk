import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'alert_logs_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF8BAADD),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.favorite_rounded, color: Color(0xFF8BAADD), size: 32),
            ),
            accountName: const Text(
              'Our Secret Space',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              'Logged in as ${FirebaseAuth.instance.currentUser?.uid.substring(0, 8)}...',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
            title: const Text('Emergency Alert', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertLogsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Color(0xFF4A6572)),
            title: const Text('Alert History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertLogsPage()));
            },
          ),
          const Divider(indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF4A6572)),
            title: const Text('About Our Space'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded, color: Color(0xFF4A6572)),
            title: const Text('Privacy & PIN'),
            onTap: () {
              Navigator.pop(context);
              _showPrivacyInfo(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Color(0xFF4A6572)),
            title: const Text('Appearance'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modern Theme is already active! ✨'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.password_rounded, color: Color(0xFF4A6572)),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.pop(context);
              _showChangePinDialog(context);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.grey),
            title: const Text('Logout', style: TextStyle(color: Colors.grey)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Color(0xFF8BAADD)),
            SizedBox(width: 12),
            Text('Privacy & PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your space is protected by a secure PIN system. It is stored locally on your device for maximum speed and privacy.',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text('PIN Status:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text('Secured Locally ✓', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 12),
            Text(
              'You can change your access code anytime using the "Change Password" option in the menu.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF8BAADD))),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final curController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Space PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: curController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current PIN'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'New 4-Digit PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BAADD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final currentPin = prefs.getString('user_pin') ?? "2908";

              final enteredCurPin = curController.text.trim();
              final enteredNewPin = newController.text.trim();

              if (enteredCurPin == currentPin) {
                if (enteredNewPin.length >= 4) {
                  await prefs.setString('user_pin', enteredNewPin);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN updated successfully! 🔐'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New PIN must be at least 4 digits')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect current PIN'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
