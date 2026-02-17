import 'package:flutter/material.dart';
import 'tutorial_page_2.dart';
import 'main_navigation.dart';
import '../services/auth_service.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final AuthService _authService = AuthService();

  Future<void> _skipToMain() async {
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
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToMain,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Color(0xFFFF6B4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Illustration
              Image.asset('images/navigation.png', height: screenHeight * 0.35),

              SizedBox(height: screenHeight * 0.04),

              // Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(true),
                  SizedBox(width: screenWidth * 0.02),
                  _buildDot(false),
                  SizedBox(width: screenWidth * 0.02),
                  _buildDot(false),
                ],
              ),

              SizedBox(height: screenHeight * 0.04),

              // Title
              Text(
                'Find What You Need',
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              Text(
                'Scan your immediate surroundings to discover students nearby ready to lend chargers, calculators, or anything else you\'re missing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Color(0xFF7F8C8D),
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TutorialPage2(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B4A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Icon(Icons.arrow_forward, size: screenWidth * 0.05),
                    ],
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
        color: isActive ? const Color(0xFFFF6B4A) : const Color(0xFFE0E0E0),
      ),
    );
  }
}
