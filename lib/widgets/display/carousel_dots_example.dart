import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

/// An improved version of ChipIndicator using the AppIcon widget
class ChipIndicatorImproved extends StatelessWidget {
  final int count;
  final int currentIndex;

  const ChipIndicatorImproved({
    Key? key,
    required this.count,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(right: index < count - 1 ? 5 : 0),
          child: AppIcon(
            iconType:
                index == currentIndex
                    ? IconType.activeDot
                    : IconType.inactiveDot,
            size: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

/// An example of how to use the improved chip indicator
class ChipIndicatorExample extends StatelessWidget {
  const ChipIndicatorExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ChipIndicatorImproved(count: 3, currentIndex: 0),
    );
  }
}
