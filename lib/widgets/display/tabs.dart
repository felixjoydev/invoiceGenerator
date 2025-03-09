import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final int initialTabIndex;
  final Function(int) onTabChanged;
  final Duration animationDuration;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    this.initialTabIndex = 0,
    required this.onTabChanged,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with SingleTickerProviderStateMixin {
  late int _activeTabIndex;
  late AnimationController _animationController;

  // Animation variables
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Schedule measuring tab widths after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (index == _activeTabIndex) return;

    setState(() {
      _activeTabIndex = index;
    });

    _updateIndicatorPosition();
    widget.onTabChanged(index);
  }

  void _updateIndicatorPosition() {
    if (!_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFCAD5D2), width: 1),
        ),
        padding: EdgeInsets.all(4),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFCAD5D2), width: 1),
      ),
      padding: EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / widget.tabs.length;

          return Stack(
            children: [
              // Animated indicator
              if (_isInitialized)
                AnimatedPositioned(
                  duration: widget.animationDuration,
                  curve: Curves.easeInOut,
                  left: tabWidth * _activeTabIndex,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(color: Color(0xFFF05022)),
                ),
              // Tab buttons
              Row(children: _buildTabButtons()),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTabButtons() {
    List<Widget> tabButtons = [];
    final int tabCount = widget.tabs.length;

    for (int i = 0; i < tabCount; i++) {
      // Add tab button
      tabButtons.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _handleTabTap(i),
            child: Container(
              // Make the container transparent since we're using a sliding indicator
              color: Colors.transparent,
              child: Center(
                child: Text(
                  widget.tabs[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        i == _activeTabIndex ? Colors.white : Color(0xFF8B9199),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return tabButtons;
  }
}
