import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingStarsWidget extends StatelessWidget {
  final double rating;
  final double size;
  final bool allowHalfRating;
  final bool ignoreGestures;
  final Function(double)? onRatingUpdate;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.allowHalfRating = true,
    this.ignoreGestures = true,
    this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: allowHalfRating,
      ignoreGestures: ignoreGestures,
      itemCount: 5,
      itemSize: size,
      itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: onRatingUpdate ?? (rating) {},
    );
  }
}

// Display Rating with Count
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double starSize;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.starSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RatingStarsWidget(
          rating: rating,
          size: starSize,
        ),
        const SizedBox(width: 6),
        Text(
          "${rating.toStringAsFixed(1)} ($totalRatings)",
          style: TextStyle(
            fontSize: starSize - 2,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}