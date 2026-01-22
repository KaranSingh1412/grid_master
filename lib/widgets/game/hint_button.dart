import 'package:flutter/material.dart';
import 'package:grid_master/constants/game_constants.dart';

class HintButton extends StatelessWidget {
  final int hints;
  final bool hasFreeHints;
  final bool canBuyHint;
  final int paidHintsRemaining;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const HintButton({
    super.key,
    required this.hints,
    required this.hasFreeHints,
    required this.canBuyHint,
    required this.paidHintsRemaining,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = hasFreeHints || canBuyHint;
    final buttonSize = isSmallScreen ? 40.0 : 48.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final containerPadding = isSmallScreen ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: GameColors.slate800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameColors.slate700.withValues(alpha: 0.5)),
      ),
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main button
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: hasFreeHints
                    ? GameColors.indigo600
                    : (canBuyHint ? GameColors.amber500 : GameColors.slate700),
                borderRadius: BorderRadius.circular(
                  isSmallScreen ? 12.0 : 16.0,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color:
                              (hasFreeHints
                                      ? GameColors.indigo600
                                      : GameColors.amber500)
                                  .withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.lightbulb,
                color: isEnabled ? Colors.white : GameColors.slate500,
                size: iconSize,
              ),
            ),

            // Badge
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasFreeHints
                      ? GameColors.indigo500
                      : GameColors.amber700,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GameColors.slate900, width: 2),
                ),
                child: hasFreeHints
                    ? Text(
                        hints.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/coin.png',
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '5',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
