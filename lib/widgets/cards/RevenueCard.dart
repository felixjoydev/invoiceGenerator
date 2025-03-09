import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/charts/revenue_chart.dart';
import 'package:invoicegenerator/theme/app_theme.dart';

class RevenueCard extends StatelessWidget {
  const RevenueCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTheme.ensureVictorMonoUppercase('Jul 2025 Revenue'),
                        style: TextStyle(
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF8D9694),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'USD',
                            style: TextStyle(
                              color: Color(0xFF8D9694),
                              fontSize: 14,
                              fontFamily: 'Victor Mono',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            '5900.00',
                            style: TextStyle(
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/up.svg',
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '15% from prev month',
                        style: TextStyle(
                          fontFamily: 'HelveticaNowDisplay',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: -0.4,
                          color: Color(0xFF8B9199),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              const RevenueChart(),
              SizedBox(height: 16),
            ],
          ),
          Container(height: 4, color: Color(0xFFCAD5D2)),
        ],
      ),
    );
  }
}
