import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';
import 'package:invoicegenerator/widgets/cards/DueCard.dart';
import 'package:invoicegenerator/widgets/display/tabs.dart';

// Import the other card types
import 'package:invoicegenerator/widgets/cards/OustandingCard.dart'
    as outstanding;
import 'package:invoicegenerator/widgets/cards/PaidCard.dart' as paid;

class OverviewCard extends StatefulWidget {
  const OverviewCard({Key? key}) : super(key: key);

  @override
  State<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<OverviewCard>
    with SingleTickerProviderStateMixin {
  int _activeTabIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTabChanged(int index) {
    setState(() {
      _activeTabIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Invoices Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF36393A),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  // Overdue section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFD61443),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                color: Color(0xFF8D9694),
                                fontSize: 10,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '1800.00',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                                fontFamily: 'Helvetica Now Display',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppTheme.ensureVictorMonoUppercase('Overdue'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Victor Mono',
                            color: Color(0xFF8D9694),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Outstanding section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFD68814),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                color: Color(0xFF8D9694),
                                fontSize: 10,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '1500.00',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                                fontFamily: 'Helvetica Now Display',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppTheme.ensureVictorMonoUppercase('Outstanding'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Victor Mono',
                            color: Color(0xFF8D9694),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Paid section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFF13AF5B),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'USD',
                              style: TextStyle(
                                color: Color(0xFF8D9694),
                                fontSize: 10,
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '5900.00',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
                                fontFamily: 'Helvetica Now Display',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppTheme.ensureVictorMonoUppercase('Paid'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Victor Mono',
                            color: Color(0xFF8D9694),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          // Tab and content section
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab bar
              CustomTabBar(
                tabs: ['Overdue', 'Outstanding', 'Paid'],
                initialTabIndex: _activeTabIndex,
                onTabChanged: _handleTabChanged,
              ),
              SizedBox(height: 16),
              // Invoice list with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCardListForActiveTab(),
              ),
              SizedBox(height: 0),
              // View all button
              Center(
                child: Text(
                  AppTheme.ensureVictorMonoUppercase('View all invoices'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Victor Mono',
                    color: Color(0xFFF05022),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Bottom border
              Container(height: 4, color: Color(0xFFCAD5D2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardListForActiveTab() {
    // Key needed for AnimatedSwitcher to recognize this as a different widget
    final key = ValueKey<int>(_activeTabIndex);

    switch (_activeTabIndex) {
      case 0: // Overdue
        return _buildCardList(key: key, cardBuilder: (i) => DueCard());
      case 1: // Outstanding
        return _buildCardList(
          key: key,
          cardBuilder: (i) => outstanding.DueCard(),
        );
      case 2: // Paid
        return _buildCardList(key: key, cardBuilder: (i) => paid.DueCard());
      default:
        return Container(key: key);
    }
  }

  Widget _buildCardList({
    required Key key,
    required Widget Function(int) cardBuilder,
    int itemCount = 3,
  }) {
    print('Building card list with itemCount: $itemCount'); // Debug print
    return Column(
      key: key,
      children: [
        for (int i = 0; i < itemCount; i++) ...[
          // Card
          cardBuilder(i),
          // Dashed divider (for all items including the last one)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CustomPaint(
              painter: DashedLinePainter(color: Color(0xFFCAD5D2)),
              size: Size(double.infinity, 1),
            ),
          ),
        ],
      ],
    );
  }
}
