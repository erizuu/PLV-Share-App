import 'package:flutter/material.dart';
import 'tutorial_page_3.dart';

class TutorialPage2 extends StatefulWidget {
  const TutorialPage2({super.key});

  @override
  State<TutorialPage2> createState() => _TutorialPage2State();
}

class _TutorialPage2State extends State<TutorialPage2> {
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
              Image.asset('images/match.png', height: screenHeight * 0.35),

              SizedBox(height: screenHeight * 0.04),

              // Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(false),
                  SizedBox(width: screenWidth * 0.02),
                  _buildDot(true),
                  SizedBox(width: screenWidth * 0.02),
                  _buildDot(false),
                ],
              ),

              SizedBox(height: screenHeight * 0.04),

              // Title
              Text(
                'Match to Borrow',
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              Text(
                'Safety first! Lending only happens when both students agree to the match. Your privacy is protected until you\'re ready to share.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Color(0xFF7F8C8D),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TutorialPage3(),
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
        color: isActive ? const Color(0xFFFF6B4A) : const Color(0xFFE0E0E0),
      ),
    );
  }
}
