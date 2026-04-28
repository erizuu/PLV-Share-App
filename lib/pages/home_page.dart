import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_details_page.dart';
import '../services/item_service.dart';
import '../utils/responsive_utils.dart';

class UShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30);

    // Create U-shape curve
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 30,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _itemService = ItemService();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = ResponsiveUtils.getResponsiveHorizontalPadding(screenWidth);
    final headerHeight = ResponsiveUtils.isTablet(context) ? 180 : 160;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header with rounded bottom
                Container(
                  height: headerHeight.toDouble(),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C3E50),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'U-Share',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(28, screenWidth, minSize: 24, maxSize: 36),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getResponsiveValue(14, screenWidth, minValue: 10, maxValue: 18),
                              vertical: ResponsiveUtils.getResponsiveValue(8, screenWidth, minValue: 6, maxValue: 10),
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white70,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getResponsiveValue(8, screenWidth, minValue: 6, maxValue: 10)),
                                Text(
                                  'INSIDE CAMPUS',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(12, screenWidth, minSize: 10, maxSize: 14),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveValue(4, screenWidth)),
                      Text(
                        'Campus only item sharing',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(14, screenWidth, minSize: 11, maxSize: 16),
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 40, horizontalPadding, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ASAP Cards Row - Use responsive columns on tablet
                            ResponsiveUtils.isTablet(context)
                                ? _buildTabletASAPCards(screenWidth)
                                : _buildPhoneASAPCards(),

                            SizedBox(height: ResponsiveUtils.getResponsiveValue(24, screenWidth, minValue: 16, maxValue: 32)),

                            // Campus Marketplace Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Campus Marketplace',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(20, screenWidth, minSize: 16, maxSize: 28),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'See All',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(14, screenWidth, minSize: 12, maxSize: 16),
                                      color: const Color(0xFFFF6B4A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: ResponsiveUtils.getResponsiveValue(12, screenWidth)),

                            // Marketplace Items
                            StreamBuilder<QuerySnapshot>(
                              stream: _itemService.getAllItems(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Center(
                                      child: Text(
                                        'No items available yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // Show only first 4 items
                                var items = snapshot.data!.docs
                                    .take(4)
                                    .toList();

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: ResponsiveUtils.getGridColumns(screenWidth),
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: ResponsiveUtils.getResponsiveGridSpacing(screenWidth),
                                    mainAxisSpacing: ResponsiveUtils.getResponsiveGridSpacing(screenWidth),
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    var doc = items[index];
                                    var item =
                                        doc.data() as Map<String, dynamic>;
                                    return _buildItemCard(item, doc.id);
                                  },
                                );
                              },
                            ),

                            SizedBox(height: ResponsiveUtils.getResponsiveValue(20, screenWidth)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Overlapping Post a Request Button
            Positioned(
              top: headerHeight.toDouble() - 28,
              left: horizontalPadding,
              right: horizontalPadding,
              child: SizedBox(
                height: ResponsiveUtils.getResponsiveButtonHeight(screenHeight),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B4A),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 24),
                      SizedBox(width: ResponsiveUtils.getResponsiveValue(8, screenWidth)),
                      Text(
                        'Post a Request',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(18, screenWidth, minSize: 14, maxSize: 22),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneASAPCards() {
    return Row(
      children: [
        // ASAP Borrowing Card
        Expanded(
          child: _buildASAPCard(
            title: 'ASAP Borrowing',
            description: 'Find students with the item you need',
            imagePath: 'images/asap.png',
            buttonColor: const Color(0xFF2C3E50),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        // Help a Peer ASAP Card
        Expanded(
          child: _buildASAPCard(
            title: 'Help a Peer ASAP',
            description: 'Respond to nearby borrowing requests',
            imagePath: 'images/help.png',
            buttonColor: const Color(0xFFFF6B4A),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTabletASAPCards(double screenWidth) {
    return Column(
      children: [
        Row(
          children: [
            // ASAP Borrowing Card
            Expanded(
              child: _buildASAPCard(
                title: 'ASAP Borrowing',
                description: 'Find students with the item you need',
                imagePath: 'images/asap.png',
                buttonColor: const Color(0xFF2C3E50),
                onTap: () {},
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveGridSpacing(screenWidth)),
            // Help a Peer ASAP Card
            Expanded(
              child: _buildASAPCard(
                title: 'Help a Peer ASAP',
                description: 'Respond to nearby borrowing requests',
                imagePath: 'images/help.png',
                buttonColor: const Color(0xFFFF6B4A),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildASAPCard({
    required String title,
    required String description,
    required String imagePath,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveValue(16, screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Image.asset(
                imagePath,
                width: 56,
                height: 56,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveValue(12, screenWidth)),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(14, screenWidth, minSize: 12, maxSize: 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveValue(6, screenWidth)),
          Text(
            description,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(11, screenWidth, minSize: 9, maxSize: 13),
              height: 1.3,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveValue(12, screenWidth)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.getResponsiveValue(10, screenWidth),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Start Scanning',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(12, screenWidth, minSize: 10, maxSize: 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String itemId) {
    final user = _auth.currentUser;
    final isOwner = user?.uid == item['ownerId'];

    return GestureDetector(
      onTap: () {
        // Only navigate to details if not the owner
        if (!isOwner) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsPage(item: item, itemId: itemId),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Area - Larger and with better styling
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                      ? Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                ),
              ),
              // Content Area
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    Text(
                      item['itemName'] ?? 'Unnamed Item',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B4A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['category'] ?? 'Other',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF6B4A),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Owner Info
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 12,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['ownerName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
