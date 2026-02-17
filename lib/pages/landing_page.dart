import 'package:flutter/material.dart';
import 'basic_information_page.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.1),

                // Logo
                Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('images/logo.png', fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'U-Share',
                  style: TextStyle(
                    fontSize: screenWidth * 0.09,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                    letterSpacing: -0.5,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Subtitle
                Text(
                  'Because learning is better\nwhen we share.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                ),

                SizedBox(height: screenHeight * 0.06),

                // Action Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset(
                      'images/Borrow.png',
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.13,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Image.asset(
                      'images/Share.png',
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.17,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Image.asset(
                      'images/Lend.png',
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.13,
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.04),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BasicInformationPage(),
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
                          'Get Started',
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

                SizedBox(height: screenHeight * 0.03),

                // Login Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: const Color(0xFF7F8C8D),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFFFF6B4A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
