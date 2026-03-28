import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ownexpense/home.dart';
import 'package:ownexpense/login.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    
    // Navigate after 2.5 seconds based on authentication state
    Timer(const Duration(seconds: 2, milliseconds: 500), () {
      _checkAuthAndNavigate();
    });
  }
  
  void _checkAuthAndNavigate() {
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is logged in, go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } else {
      // User is not logged in, go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Money/Finance Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset('assets/images/money.png'),
            ),
            
            SizedBox(height: 30),
            
            // App Name
            Text(
              'OwnExpense',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                letterSpacing: 1.2,
              ),
            ),
            
            SizedBox(height: 10),
            
            // Loading indicator
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: Colors.green.shade600,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Tagline
            Text(
              'Track Your Expenses',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}