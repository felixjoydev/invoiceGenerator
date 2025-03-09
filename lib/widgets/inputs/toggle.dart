import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool>? onChanged;
  final bool isDisabled;

  const CustomCheckbox({
    Key? key,
    this.isChecked = false,
    this.onChanged,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controller with fast duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Initialize the slide animation
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set initial animation state based on isChecked
    if (widget.isChecked) {
      _animationController.value = 1.0;
    } else {
      _animationController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation when isChecked changes (but only when enabled)
    if (widget.isChecked != oldWidget.isChecked && !widget.isDisabled) {
      if (widget.isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    // Handle changes in disabled state
    if (widget.isDisabled != oldWidget.isDisabled) {
      // If becoming disabled, update animation value instantly
      if (widget.isDisabled) {
        _animationController.value = widget.isChecked ? 1.0 : 0.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on disabled state
    final Color borderColor =
        widget.isDisabled ? const Color(0xFF768581) : const Color(0xFF373C3A);

    final Color toggleColor = const Color(0xFFF05022);
    final Color disabledToggleColor = const Color(0xFF768581);

    // For disabled state, we want it to behave like a traditional toggle
    // - If disabled and checked: gray box on right
    // - If disabled and unchecked: gray box on left
    // - If enabled and checked: orange box on right
    // - If enabled and unchecked: orange box on left

    return GestureDetector(
      onTap:
          widget.isDisabled
              ? null
              : () {
                if (widget.onChanged != null) {
                  widget.onChanged!(!widget.isChecked);
                }
              },
      child: Container(
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(2), // Adding 4px padding on all sides
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
        ),
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            double position;
            Color boxColor;

            if (widget.isDisabled) {
              // When disabled, the toggle should be on the left (0px from container padding)
              position = 0.0;
              boxColor = disabledToggleColor;
            } else {
              // When enabled:
              // - If unchecked: position on the left (0px from container padding)
              // - If checked: position on the right (16px from left padding)
              final double startPosition = 0.0;
              final double endPosition =
                  16.0; // Available width inside padding (32-16)
              position =
                  startPosition +
                  (_slideAnimation.value * (endPosition - startPosition));
              boxColor = toggleColor;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: position, // Position based on state
                  child: Container(width: 16, height: 16, color: boxColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Example usage with StatefulWidget
class CheckboxExample extends StatefulWidget {
  const CheckboxExample({Key? key}) : super(key: key);

  @override
  State<CheckboxExample> createState() => _CheckboxExampleState();
}

class _CheckboxExampleState extends State<CheckboxExample> {
  bool _isChecked = false;
  bool _isDisabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomCheckbox(
              isChecked: _isChecked,
              isDisabled: _isDisabled,
              onChanged: (value) {
                setState(() {
                  _isChecked = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isDisabled = !_isDisabled;
                });
              },
              child: Text(_isDisabled ? 'Enable' : 'Disable'),
            ),
          ],
        ),
      ),
    );
  }
}
