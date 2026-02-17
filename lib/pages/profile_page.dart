import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Import your login page

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  int sharedCount = 0;
  int borrowedCount = 0;
  double trustScore = 0.0;
  int successfulExchanges = 0;
  List<String> earnedBadges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (currentUser == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Get user profile data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
      }

      // Get items shared count (items where user is lender)
      QuerySnapshot sharedItems = await _firestore
          .collection('items')
          .where('lenderId', isEqualTo: currentUser!.uid)
          .get();

      // Get items borrowed count (transactions where user is borrower and completed)
      QuerySnapshot borrowedTransactions = await _firestore
          .collection('transactions')
          .where('borrowerId', isEqualTo: currentUser!.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      // Get successful exchanges (completed transactions as lender)
      QuerySnapshot lenderTransactions = await _firestore
          .collection('transactions')
          .where('lenderId', isEqualTo: currentUser!.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      // Calculate trust score (based on ratings from borrowers)
      double averageRating = 0.0;
      int ratedCount = 0;

      if (lenderTransactions.docs.isNotEmpty) {
        double totalRating = 0.0;

        for (var transaction in lenderTransactions.docs) {
          var data = transaction.data() as Map<String, dynamic>;
          if (data.containsKey('borrowerRating') &&
              data['borrowerRating'] != null) {
            totalRating += (data['borrowerRating'] as num).toDouble();
            ratedCount++;
          }
        }

        if (ratedCount > 0) {
          averageRating = totalRating / ratedCount;
        }
      }

      // If no ratings yet, default to 5.0 but show as new user
      trustScore = averageRating > 0 ? averageRating : 5.0;
      sharedCount = sharedItems.docs.length;
      borrowedCount = borrowedTransactions.docs.length;
      successfulExchanges = lenderTransactions.docs.length;

      // Determine earned badges based on actual activity
      List<String> badges = [];

      // Always on Time badge (check if user has no late returns as borrower)
      if (borrowedCount > 0) {
        QuerySnapshot lateReturns = await _firestore
            .collection('transactions')
            .where('borrowerId', isEqualTo: currentUser!.uid)
            .where('status', isEqualTo: 'completed')
            .where('isLate', isEqualTo: true)
            .get();

        if (lateReturns.docs.isEmpty) {
          badges.add('Always on Time');
        }
      }

      // Quick Responder badge (check response time as lender)
      if (sharedCount >= 3) {
        QuerySnapshot quickResponses = await _firestore
            .collection('transactions')
            .where('lenderId', isEqualTo: currentUser!.uid)
            .where('responseTime', isLessThan: 3600) // Responded within 1 hour
            .get();

        if (quickResponses.docs.length >= 3) {
          badges.add('Quick Responder');
        }
      }

      // Trusted Lender badge (if has 5+ successful exchanges)
      if (successfulExchanges >= 5) {
        badges.add('Trusted Lender');
      }

      // First Exchange badge
      if (successfulExchanges >= 1) {
        badges.add('First Exchange');
      }

      if (mounted) {
        setState(() {
          earnedBadges = badges;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String getFullName() {
    if (userData != null && userData!.containsKey('fullName')) {
      return userData!['fullName'] ?? 'No Name';
    }
    return currentUser?.displayName ?? 'User';
  }

  String getEmail() {
    return currentUser?.email ?? 'No email';
  }

  String getCourse() {
    if (userData != null && userData!.containsKey('course')) {
      return userData!['course'] ?? 'No Course';
    }
    return 'No Course';
  }

  String getSection() {
    if (userData != null && userData!.containsKey('section')) {
      return userData!['section'] ?? 'No Section';
    }
    return 'No Section';
  }

  String getSchoolId() {
    if (userData != null && userData!.containsKey('schoolId')) {
      return userData!['schoolId'] ?? 'No School ID';
    }
    return 'No School ID';
  }

  String getVerificationStatus() {
    if (userData != null && userData!.containsKey('verificationStatus')) {
      return userData!['verificationStatus'] ?? 'pending';
    }
    return 'pending';
  }

  bool isTop10Percent() {
    return successfulExchanges >= 5;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Navigate to LoginPage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Not logged in',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B4A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B4A)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Profile Info
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C3E50),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.03,
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              image: currentUser?.photoURL != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        currentUser!.photoURL!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : const DecorationImage(
                                      image: AssetImage(
                                        'images/profile_placeholder.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: currentUser?.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white70,
                                  )
                                : null,
                          ),
                          // Verification Badge
                          if (getVerificationStatus() == 'verified')
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Name and Details
                      Text(
                        getFullName(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getEmail(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${getCourse()} - ${getSection()}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getVerificationStatus() == 'verified'
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getVerificationStatus().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Lender Trust Score Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'LENDER TRUST SCORE',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trustScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'OUT OF 5',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < trustScore.floor()
                                      ? Icons.star
                                      : index < trustScore
                                      ? Icons.star_half
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            if (isTop10Percent())
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B4A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Top 10% of Campus Lenders',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              successfulExchanges > 0
                                  ? 'Based on $successfulExchanges successful exchange${successfulExchanges != 1 ? 's' : ''}'
                                  : 'No exchanges yet',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Section
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  children: [
                    // Shared Stats
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$sharedCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SHARED',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Items provided to others',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),

                    // Borrowed Stats
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$borrowedCount',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'BORROWED',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Items used from campus',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Earned Badges Section
              if (earnedBadges.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earned Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: earnedBadges.map((badge) {
                          IconData iconData;
                          Color badgeColor = const Color(0xFFFF6B4A);

                          switch (badge) {
                            case 'Always on Time':
                              iconData = Icons.access_time;
                              break;
                            case 'Quick Responder':
                              iconData = Icons.flash_on;
                              break;
                            case 'Trusted Lender':
                              iconData = Icons.emoji_events;
                              badgeColor = Colors.amber;
                              break;
                            case 'First Exchange':
                              iconData = Icons.stars;
                              badgeColor = Colors.blue;
                              break;
                            default:
                              iconData = Icons.star;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: screenHeight * 0.03),

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
