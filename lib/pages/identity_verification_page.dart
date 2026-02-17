import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'final_step_page.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class IdentityVerificationPage extends StatefulWidget {
  final String userId;

  const IdentityVerificationPage({super.key, required this.userId});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVerification;
  String? _frontIdFileName;
  String? _backIdFileName;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  final List<String> _verificationTypes = [
    'School ID',
    'Driver\'s License',
    'Passport',
    'National ID',
  ];

  Future<void> _pickFile(bool isFrontId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        if (isFrontId) {
          _frontIdFileName = result.files.single.name;
        } else {
          _backIdFileName = result.files.single.name;
        }
      });
    }
  }

  Future<void> _handleNext() async {
    if (_selectedVerification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an identity verification type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Note: File upload to Firebase Storage would go here
    // For now, we're just saving the file names
    final success = await _authService.updateVerificationInfo(
      uid: widget.userId,
      verificationType: _selectedVerification!,
      frontIdPath: _frontIdFileName,
      backIdPath: _backIdFileName,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalStepPage(userId: widget.userId),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save verification info'),
          backgroundColor: Colors.red,
        ),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.08),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.025),

                  // Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(false),
                      SizedBox(width: screenWidth * 0.02),
                      _buildDot(false),
                      SizedBox(width: screenWidth * 0.02),
                      _buildDot(true),
                      SizedBox(width: screenWidth * 0.02),
                      _buildDot(false),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Title
                  Center(
                    child: Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Choose Identity Verification
                  Text(
                    'Choose Identity Verification',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  DropdownButtonFormField<String>(
                    value: _selectedVerification,
                    decoration: InputDecoration(
                      hintText: 'School ID',
                      hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                    ),
                    items: _verificationTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVerification = newValue;
                      });
                    },
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Upload Required Image
                  Text(
                    'Upload Required Image',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),

                  // Front ID
                  Text(
                    'Front ID',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF7F8C8D),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _pickFile(true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2C3E50),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.01,
                            ),
                          ),
                          child: Text(
                            'Choose File',
                            style: TextStyle(fontSize: screenWidth * 0.035),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            _frontIdFileName ?? 'No chosen file',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Color(0xFF7F8C8D),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Back ID
                  Text(
                    'Back ID',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF7F8C8D),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _pickFile(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2C3E50),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.01,
                            ),
                          ),
                          child: Text(
                            'Choose File',
                            style: TextStyle(fontSize: screenWidth * 0.035),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            _backIdFileName ?? 'No chosen file',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Color(0xFF7F8C8D),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2C3E50),
                        backgroundColor: const Color(0xFFCBD5E1),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
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
                                Icon(
                                  Icons.arrow_forward,
                                  size: screenWidth * 0.05,
                                ),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Login Link
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
                            color: Color(0xFF2C3E50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFFF6B4A) : const Color(0xFFE0E0E0),
      ),
    );
  }
}
