import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/charts/revenue_chart.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/services/revenue_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RevenueService>(
      builder: (context, revenueService, child) {
        final selectedMonth = revenueService.selectedMonth;
        final monthYearText = DateFormat('MMM yyyy').format(selectedMonth);
        final revenue = revenueService.getSelectedMonthRevenue();
        final formattedRevenue = NumberFormat('#,##0.00').format(revenue);

        final percentChange =
            revenueService.getPercentChangeFromPreviousMonth();
        final isUp = revenueService.isRevenueUp();
        final absPercentChange = percentChange.abs().toStringAsFixed(0);

        return SizedBox(
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
                      GestureDetector(
                        // Only in debug mode - double tap on title to refresh data
                        onDoubleTap:
                            kDebugMode
                                ? () {
                                  revenueService.calculateAllMonthlyRevenues();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Revenue data refreshed'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                                : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTheme.ensureVictorMonoUppercase(
                                '$monthYearText Revenue',
                              ),
                              style: TextStyle(
                                fontFamily: 'Victor Mono',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFFF05022),
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
                                SizedBox(width: 4),
                                Text(
                                  formattedRevenue,
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
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            isUp
                                ? 'assets/icons/up.svg'
                                : 'assets/icons/down.svg',
                            width: 24,
                            height: 24,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$absPercentChange% from prev month',
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
                  SizedBox(height: 16),
                  const RevenueChart(),
                  SizedBox(height: 16),
                ],
              ),
              Container(height: 4, color: Color(0xFFCAD5D2)),
            ],
          ),
        );
      },
    );
  }
}
