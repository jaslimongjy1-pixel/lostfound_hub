import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'user_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));

    // Access SharedPreferences to check status
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      // Retrieve saved user details
      final String id = prefs.getString('user_id') ?? '';
      final String name = prefs.getString('user_name') ?? '';
      final String email = prefs.getString('user_email') ?? '';
      final String role = prefs.getString('user_role') ?? 'user';

      // Create the User object to satisfy the 'required' requirement
      final user = UserModel(id: id, name: name, email: email, role: role);

      // Navigate to Main Screen and pass the user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserMainScreen(user: user)),
      );
    } else {
      // If not logged in, go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            SizedBox(height: 20),
            Text(
              "LostFoundHub",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
