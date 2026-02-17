import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/auth_service.dart';

class TutorialPage3 extends StatefulWidget {
  const TutorialPage3({super.key});

  @override
  State<TutorialPage3> createState() => _TutorialPage3State();
}

class _TutorialPage3State extends State<TutorialPage3> {
  final AuthService _authService = AuthService();

  Future<void> _completeTutorial() async {
    await _authService.markTutorialAsSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.08),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Illustration
              Image.asset('images/campus.png', height: screenHeight * 0.35),

              SizedBox(height: screenHeight * 0.04),

              // Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(false),
                  SizedBox(width: screenWidth * 0.02),
                  _buildDot(false),
                  SizedBox(width: screenWidth * 0.02),
                  _buildDot(true),
                ],
              ),

              SizedBox(height: screenHeight * 0.04),

              // Title
              Text(
                'Campus-Only Sharing',
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              Text(
                'For your security, all sharing happens within campus grounds. Items are scanned on-site and must be returned by end-of-day.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Color(0xFF7F8C8D),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  onPressed: _completeTutorial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6B8F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Back Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? const Color(0xFF5B6B8F) : const Color(0xFFE0E0E0),
      ),
    );
  }
}
