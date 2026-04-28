import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'basic_information_page.dart';
import 'login_page.dart';
import 'main_navigation.dart';
import '../utils/responsive_utils.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  void _checkUserLoggedIn() {
    // Check if user is already logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // User is already logged in, navigate to MainNavigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user is logged in, return an empty scaffold while redirecting
    if (FirebaseAuth.instance.currentUser != null) {
      return const Scaffold(
        body: SizedBox.expand(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = ResponsiveUtils.getResponsiveHorizontalPadding(screenWidth);
    final logoSize = ResponsiveUtils.getResponsiveImageSize(130, screenWidth, minSize: 100, maxSize: 180);
    final buttonHeight = ResponsiveUtils.getResponsiveButtonHeight(screenHeight);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),

                // Logo
                Container(
                  width: logoSize,
                  height: logoSize,
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

                SizedBox(height: ResponsiveUtils.getResponsiveValue(24, screenWidth, minValue: 16, maxValue: 32)),

                // Title
                Text(
                  'U-Share',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(36, screenWidth, minSize: 28, maxSize: 48),
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
                    fontSize: ResponsiveUtils.getResponsiveFontSize(16, screenWidth, minSize: 12, maxSize: 20),
                    color: const Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                ),

                SizedBox(height: screenHeight * 0.06),

                // Action Icons Row - Responsive for different screen sizes
                ResponsiveUtils.isTablet(context)
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Image.asset(
                                'images/Borrow.png',
                                width: screenWidth * 0.18,
                                height: screenHeight * 0.12,
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Image.asset(
                                'images/Share.png',
                                width: screenWidth * 0.25,
                                height: screenHeight * 0.15,
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Image.asset(
                                'images/Lend.png',
                                width: screenWidth * 0.18,
                                height: screenHeight * 0.12,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
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
                  height: buttonHeight,
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
                            fontSize: ResponsiveUtils.getResponsiveFontSize(16, screenWidth, minSize: 14, maxSize: 20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Icon(Icons.arrow_forward, size: ResponsiveUtils.getResponsiveValue(20, screenWidth, minValue: 16, maxValue: 24)),
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
                        fontSize: ResponsiveUtils.getResponsiveFontSize(14, screenWidth, minSize: 11, maxSize: 16),
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
                          fontSize: ResponsiveUtils.getResponsiveFontSize(14, screenWidth, minSize: 11, maxSize: 16),
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
