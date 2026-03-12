import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class ImageService {
  // ImgBB API credentials
  static const String _imgbbApiKey = '4c809ae7dbd7adec1e245d305d302f77';
  static const String _imgbbApiUrl = 'https://api.imgbb.com/1/upload';

  // Upload item image to ImgBB
  Future<Map<String, dynamic>> uploadItemImage({
    required File imageFile,
    required String itemId,
  }) async {
    try {
      // Read image file as bytes
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_imgbbApiUrl));

      // Add parameters
      request.fields['key'] = _imgbbApiKey;
      request.fields['image'] = base64Image;
      request.fields['name'] = 'item_$itemId';

      // Send request
      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image upload took too long');
        },
      );

      // Parse response
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final imageUrl = jsonResponse['data']['image']['url'];
        return {
          'success': true,
          'imageUrl': imageUrl,
          'message': 'Image uploaded successfully',
        };
      } else {
        final errorMessage =
            jsonResponse['error']['message'] ?? 'Unknown error';
        return {'success': false, 'message': 'Upload failed: $errorMessage'};
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Image upload timed out. Please try again.',
      };
    } catch (e) {
      print('Error uploading image: $e');
      return {'success': false, 'message': 'Failed to upload image: $e'};
    }
  }
}
