import 'package:flutter/material.dart';

class VerificationInProgressPage extends StatelessWidget {
  final String userId;

  const VerificationInProgressPage({super.key, required this.userId});

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Illustration
              Image.asset(
                'images/verification_in_progress.png',
                height: screenHeight * 0.31,
              ),

              SizedBox(height: screenHeight * 0.06),

              // Title
              Text(
                'Verification in Progress',
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              Text(
                'Our team is verifying your student\nidentity. This usually takes less than 24\nhours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: const Color(0xFF7F8C8D),
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Got It Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to appropriate screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got It!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Return to Login
              TextButton(
                onPressed: () {
                  // TODO: Navigate to login
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Return to Login',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
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
}
