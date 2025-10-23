import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  final double rating;
  final int maxRating;
  final double size;
  final bool allowHalfRating;
  final bool isReadOnly;
  final Color filledColor;
  final Color unfilledColor;
  final Color borderColor;
  final IconData filledIcon;
  final IconData unfilledIcon;
  final Function(double)? onRatingChanged;
  final MainAxisAlignment alignment;
  final double spacing;

  const StarRatingWidget({
    Key? key,
    this.rating = 0.0,
    this.maxRating = 5,
    this.size = 24.0,
    this.allowHalfRating = true,
    this.isReadOnly = false,
    this.filledColor = const Color(0xFF2D7A6E),
    this.unfilledColor = Colors.grey,
    this.borderColor = Colors.grey,
    this.filledIcon = Icons.star,
    this.unfilledIcon = Icons.star_border,
    this.onRatingChanged,
    this.alignment = MainAxisAlignment.start,
    this.spacing = 2.0,
  }) : super(key: key);

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  double _currentRating = 0.0;
  double _hoverRating = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  void _updateRating(double newRating) {
    if (widget.isReadOnly) return;

    setState(() {
      _currentRating = newRating;
    });

    widget.onRatingChanged?.call(newRating);
  }

  void _onStarTap(int starIndex) {
    if (widget.isReadOnly) return;

    double newRating = starIndex + 1.0;
    _updateRating(newRating);
  }

  void _onStarPanUpdate(
      int starIndex, DragUpdateDetails details, BuildContext context) {
    if (widget.isReadOnly || !widget.allowHalfRating) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final starWidth = widget.size + widget.spacing;
    final relativePosition = (localPosition.dx % starWidth) / widget.size;

    double newRating = starIndex.toDouble();
    if (relativePosition > 0.75) {
      newRating += 1.0;
    } else if (relativePosition > 0.25) {
      newRating += 0.5;
    }

    newRating = newRating.clamp(0.0, widget.maxRating.toDouble());
    _updateRating(newRating);
  }

  Widget _buildStar(int index) {
    final double starRating = _hoverRating > 0 ? _hoverRating : _currentRating;
    final bool isFilled = starRating > index;
    final bool isHalfFilled =
        widget.allowHalfRating && starRating > index && starRating < index + 1;

    if (isHalfFilled) {
      return _buildHalfStar();
    }

    return Icon(
      isFilled ? widget.filledIcon : widget.unfilledIcon,
      size: widget.size,
      color: isFilled ? widget.filledColor : widget.unfilledColor,
    );
  }

  Widget _buildHalfStar() {
    return Stack(
      children: [
        Icon(
          widget.unfilledIcon,
          size: widget.size,
          color: widget.unfilledColor,
        ),
        ClipRect(
          clipper: _HalfClipper(),
          child: Icon(
            widget.filledIcon,
            size: widget.size,
            color: widget.filledColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) {
        if (!widget.isReadOnly) {
          setState(() {
            _hoverRating = 0.0;
          });
        }
      },
      child: Row(
        mainAxisAlignment: widget.alignment,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.maxRating, (index) {
          return MouseRegion(
            onEnter: (_) {
              if (!widget.isReadOnly) {
                setState(() {
                  _hoverRating = index + 1.0;
                });
              }
            },
            child: GestureDetector(
              onTap: () => _onStarTap(index),
              onPanUpdate: widget.allowHalfRating
                  ? (details) => _onStarPanUpdate(index, details, context)
                  : null,
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < widget.maxRating - 1 ? widget.spacing : 0,
                ),
                child: _buildStar(index),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

// Compact Star Rating Display (for lists and cards)
class CompactStarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;
  final Color starColor;
  final TextStyle? textStyle;
  final bool showReviewCount;

  const CompactStarRating({
    Key? key,
    required this.rating,
    this.reviewCount = 0,
    this.size = 14.0,
    this.starColor = const Color(0xFF2D7A6E),
    this.textStyle,
    this.showReviewCount = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TextStyle(
      fontSize: size - 2,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size,
          color: starColor,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: textStyle ?? defaultTextStyle,
        ),
        if (showReviewCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: (textStyle ?? defaultTextStyle).copyWith(
              color: Colors.grey[500],
              fontSize: (textStyle?.fontSize ?? defaultTextStyle.fontSize!) - 1,
            ),
          ),
        ],
      ],
    );
  }
}

// Rating Distribution Bar Chart
class RatingDistributionWidget extends StatelessWidget {
  final Map<int, int> distribution;
  final int totalReviews;
  final double height;
  final Color barColor;
  final Function(int)? onStarTap;

  const RatingDistributionWidget({
    Key? key,
    required this.distribution,
    required this.totalReviews,
    this.height = 8.0,
    this.barColor = const Color(0xFF2D7A6E),
    this.onStarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(5, (index) {
        final starRating = 5 - index; // Start from 5 stars
        final count = distribution[starRating] ?? 0;
        final percentage = count / totalReviews;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: GestureDetector(
            onTap: onStarTap != null ? () => onStarTap!(starRating) : null,
            child: Row(
              children: [
                // Star number
                Text(
                  '$starRating',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star,
                  size: 12,
                  color: Color(0xFF2D7A6E),
                ),
                const SizedBox(width: 8),

                // Progress bar
                Expanded(
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                // Count
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// Large Rating Summary Widget
class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;
  final double starSize;
  final TextStyle? ratingTextStyle;
  final TextStyle? countTextStyle;

  const RatingSummaryWidget({
    Key? key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
    this.starSize = 24.0,
    this.ratingTextStyle,
    this.countTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultRatingStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.grey[800],
    );

    final defaultCountStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Average rating and stars
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: ratingTextStyle ?? defaultRatingStyle,
            ),
            const SizedBox(height: 4),
            StarRatingWidget(
              rating: averageRating,
              size: starSize,
              isReadOnly: true,
            ),
            const SizedBox(height: 4),
            Text(
              '$totalReviews review${totalReviews != 1 ? 's' : ''}',
              style: countTextStyle ?? defaultCountStyle,
            ),
          ],
        ),

        const SizedBox(width: 24),

        // Right side - Distribution bars
        Expanded(
          child: RatingDistributionWidget(
            distribution: distribution,
            totalReviews: totalReviews,
          ),
        ),
      ],
    );
  }
}
