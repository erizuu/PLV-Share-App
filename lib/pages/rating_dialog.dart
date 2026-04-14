import 'package:flutter/material.dart';
import 'rating_service.dart';

class RatingDialog extends StatefulWidget {
  final String ratedUserId;
  final String ratedUserName;
  final String ratingType; // 'lender' or 'borrower'
  final String transactionId;

  const RatingDialog({
    super.key,
    required this.ratedUserId,
    required this.ratedUserName,
    required this.ratingType,
    required this.transactionId,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 5.0;
  TextEditingController feedbackController = TextEditingController();
  bool isSubmitting = false;
  final RatingService _ratingService = RatingService();

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  Future<void> submitRating() async {
    if (feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide feedback'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      bool success = await _ratingService.submitRating(
        ratedUserId: widget.ratedUserId,
        ratingType: widget.ratingType,
        rating: rating,
        feedback: feedbackController.text.trim(),
        transactionId: widget.transactionId ?? '',
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rating submitted successfully! 🎉'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have already rated this user as a ${widget.ratingType == 'lender' ? 'Lender' : 'Borrower'}. You can only rate them once per role.',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String typeLabel = widget.ratingType == 'lender' ? 'Lender' : 'Borrower';

    return AlertDialog(
      title: Text(
        'Rate ${widget.ratedUserName} as a $typeLabel',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),

            // Star Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Rating: ${rating.toStringAsFixed(1)}/5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          rating = (index + 1).toDouble();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < rating.floor()
                              ? Icons.star
                              : index < rating
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Feedback TextField
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this $typeLabel...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B4A),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B4A),
            foregroundColor: Colors.white,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Text('Submit Rating'),
        ),
      ],
    );
  }
}
