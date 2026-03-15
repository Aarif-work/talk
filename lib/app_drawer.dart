import 'package:flutter/material.dart';
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
            leading: const Icon(Icons.more_horiz_rounded, color: Color(0xFF4A6572)),
            title: const Text('More Settings'),
            onTap: () => Navigator.pop(context),
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
}
