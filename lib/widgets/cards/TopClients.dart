import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';

class TopClients extends StatelessWidget {
  const TopClients({Key? key}) : super(key: key);

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
              Text(
                'Top Clients',
                style: TextStyle(
                  color: Color(0xFF36393A),
                  fontSize: 24,
                  fontFamily: 'Helvetica Now Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // First client
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Acuro',
                            style: TextStyle(
                              color: Color(0xFF3A3A3A),
                              fontSize: 16,
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(width: 7),
                              Text(
                                '4500.00',
                                style: TextStyle(
                                  color: Color(0xFF3A3A3A),
                                  fontSize: 16,
                                  fontFamily: 'Helvetica Now Display',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 12,
                        color: Color(0xFFB7C2BF),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 256,
                            height: 12,
                            color: Color(0xFF768681),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Second client
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Micro Company',
                            style: TextStyle(
                              color: Color(0xFF3A3A3A),
                              fontSize: 16,
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(width: 7),
                              Text(
                                '4500.00',
                                style: TextStyle(
                                  color: Color(0xFF3A3A3A),
                                  fontSize: 16,
                                  fontFamily: 'Helvetica Now Display',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 12,
                        color: Color(0xFFB7C2BF),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 228,
                            height: 12,
                            color: Color(0xFF768681),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Third client
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Huku Inc',
                            style: TextStyle(
                              color: Color(0xFF3A3A3A),
                              fontSize: 16,
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(width: 7),
                              Text(
                                '4500.00',
                                style: TextStyle(
                                  color: Color(0xFF3A3A3A),
                                  fontSize: 16,
                                  fontFamily: 'Helvetica Now Display',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 12,
                        color: Color(0xFFB7C2BF),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 189,
                            height: 12,
                            color: Color(0xFF768681),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Fourth client
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fortanix',
                            style: TextStyle(
                              color: Color(0xFF3A3A3A),
                              fontSize: 16,
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(width: 7),
                              Text(
                                '4500.00',
                                style: TextStyle(
                                  color: Color(0xFF3A3A3A),
                                  fontSize: 16,
                                  fontFamily: 'Helvetica Now Display',
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 12,
                        color: Color(0xFFB7C2BF),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 43,
                            height: 12,
                            color: Color(0xFF768681),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              AppTheme.ensureVictorMonoUppercase('View all clients'),
              style: TextStyle(
                color: Color(0xFFF05022),
                fontSize: 14,
                fontFamily: 'Victor Mono',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          Container(height: 4, color: Color(0xFFCAD5D2)),
        ],
      ),
    );
  }
}
