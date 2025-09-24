import 'package:flutter/material.dart';
import 'package:matrix4_transform/matrix4_transform.dart';

// Animation constants
const Color kInactiveGradientStartColor = Colors.grey;
const Color kInactiveGradientEndColor = Colors.grey;

const Color kActiveGradientStartColor = Color(0xFF0046FF);
const Color kActiveGradientEndColor = Color(0xFFFF8040);

const double kActiveOpacity = 1.0;
const double kInactiveOpacity = 0.3;

const double kInactiveHeight = 200;
const double kInactiveWidth = 300;

const double kActiveHeight = 340;
const double kActiveWidth = 340;

class CardModel {
  bool activeState;
  double opacity;
  double rotation;
  Offset rotationOffset;
  Widget cardContent;
  String cardId;

  CardModel({
    this.activeState = false,
    this.opacity = 1.0,
    this.rotation = 0,
    this.rotationOffset = const Offset(0, 0),
    required this.cardContent,
    required this.cardId,
  });
}

typedef CardActionCallback = void Function(String cardId, String action);

class AnimatedCardStack extends StatefulWidget {
  final List<Widget> cards;
  final CardActionCallback? onCardAction;
  final bool showActionButtons;
  final String leftActionIcon;
  final String rightActionIcon;
  final Color leftActionColor;
  final Color rightActionColor;

  const AnimatedCardStack({
    Key? key,
    required this.cards,
    this.onCardAction,
    this.showActionButtons = true,
    this.leftActionIcon = 'skip',
    this.rightActionIcon = 'favorite',
    this.leftActionColor = Colors.grey,
    this.rightActionColor = Colors.green,
  }) : super(key: key);

  @override
  State<AnimatedCardStack> createState() => _AnimatedCardStackState();
}

class _AnimatedCardStackState extends State<AnimatedCardStack> {
  List<CardModel> cardModels = [];

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  @override
  void didUpdateWidget(AnimatedCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.length != oldWidget.cards.length) {
      _initializeCards();
    }
  }

  void _initializeCards() {
    cardModels.clear();
    
    for (int i = widget.cards.length - 1; i >= 0; i--) {
      cardModels.add(
        CardModel(
          activeState: i == 0, // First card is active
          cardContent: widget.cards[i],
          cardId: 'card_$i',
        ),
      );
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _nextCard() {
    if (cardModels.isEmpty) return;
    
    // Find the current active card
    int activeIndex = cardModels.indexWhere((card) => card.activeState);
    if (activeIndex == -1) return;
    
    // Animate current card out (right swipe)
    _animateCardOut(cardModels[activeIndex], isRightSwipe: true);
    
    // Activate next card after delay
    if (activeIndex > 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            cardModels[activeIndex - 1].activeState = true;
          });
        }
      });
    }
  }

  void _previousCard() {
    if (cardModels.isEmpty) return;
    
    // Find the current active card
    int activeIndex = cardModels.indexWhere((card) => card.activeState);
    if (activeIndex == -1) return;
    
    // Animate current card out (left swipe)
    _animateCardOut(cardModels[activeIndex], isRightSwipe: false);
    
    // Activate next card after delay
    if (activeIndex > 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            cardModels[activeIndex - 1].activeState = true;
          });
        }
      });
    }
  }

  void _animateCardOut(CardModel card, {required bool isRightSwipe}) {
    setState(() {
      card.activeState = false;
      card.rotation = isRightSwipe ? 45 : -45;
      card.rotationOffset = isRightSwipe 
          ? Offset(kActiveWidth, kActiveHeight) 
          : Offset(0, kActiveHeight);
      card.opacity = 0;
    });

    // Notify parent about card action
    if (widget.onCardAction != null) {
      widget.onCardAction!(
        card.cardId, 
        isRightSwipe ? widget.rightActionIcon : widget.leftActionIcon
      );
    }
  }

  void _resetCards() {
    _initializeCards();
  }

  @override
  Widget build(BuildContext context) {
    if (cardModels.isEmpty) {
      return Container(
        height: kActiveHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No more cards',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _resetCards,
                icon: Icon(Icons.refresh),
                label: Text('Reset Cards'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0046FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: kActiveHeight + 80, // Extra space for buttons
      child: Stack(
        children: [
          // Card Stack
          ...cardModels.map((card) {
            return Align(
              alignment: Alignment.center,
              child: AnimatedCardWidget(
                cardModel: card,
                onLeftAction: widget.showActionButtons ? _previousCard : null,
                onRightAction: widget.showActionButtons ? _nextCard : null,
                leftActionColor: widget.leftActionColor,
                rightActionColor: widget.rightActionColor,
              ),
            );
          }).toList(),
          
          // Navigation dots (optional)
          if (cardModels.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: cardModels.asMap().entries.map((entry) {
                  CardModel card = entry.value;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: card.activeState 
                          ? Color(0xFF0046FF) 
                          : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedCardWidget extends StatelessWidget {
  final CardModel cardModel;
  final VoidCallback? onLeftAction;
  final VoidCallback? onRightAction;
  final Color leftActionColor;
  final Color rightActionColor;

  const AnimatedCardWidget({
    Key? key,
    required this.cardModel,
    this.onLeftAction,
    this.onRightAction,
    this.leftActionColor = Colors.grey,
    this.rightActionColor = Colors.green,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: cardModel.opacity == 0,
      child: AnimatedOpacity(
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 600),
        opacity: cardModel.opacity,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.bounceOut,
          transform: cardModel.rotation != 0
              ? Matrix4Transform()
                  .rotateDegrees(cardModel.rotation,
                      origin: cardModel.rotationOffset)
                  .matrix4
              : null,
          margin: EdgeInsets.only(
            top: cardModel.activeState ? 20 : 40,
            bottom: cardModel.activeState ? 20 : 40,
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 800),
            curve: Curves.bounceOut,
            height: cardModel.activeState ? kActiveHeight : kInactiveHeight,
            width: cardModel.activeState ? kActiveWidth : kInactiveWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: cardModel.activeState
                    ? [kActiveGradientStartColor, kActiveGradientEndColor]
                    : [kInactiveGradientStartColor, kInactiveGradientEndColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (cardModel.activeState)
                  BoxShadow(
                    color: kActiveGradientEndColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Card content
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: cardModel.cardContent,
                  ),
                ),
                
                // Action buttons overlay (only show on active card)
                if (cardModel.activeState && (onLeftAction != null || onRightAction != null))
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: cardModel.activeState ? kActiveOpacity : kInactiveOpacity,
                      duration: Duration(milliseconds: 600),
                      child: IgnorePointer(
                        ignoring: !cardModel.activeState,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (onLeftAction != null)
                                Padding(
                                  padding: EdgeInsets.all(20),
                                  child: GestureDetector(
                                    onTap: onLeftAction,
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: leftActionColor,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              if (onRightAction != null)
                                Padding(
                                  padding: EdgeInsets.all(20),
                                  child: GestureDetector(
                                    onTap: onRightAction,
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.favorite,
                                        color: rightActionColor,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}