import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to',
            style: TextStyle(
              fontSize: 48,
              fontFamily: 'HelveticaNowDisplay',
              fontWeight: FontWeight.w700,
              color: Color(0xFF373C3A),
              height: 1.2,
              letterSpacing: -2,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
          SizedBox(height: 4),
          Container(
            width: 132,
            height: 52.71,
            decoration: BoxDecoration(
              color: Color(0xFFF05022),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/invo.svg',
                width: 110.39,
                height: 40.29,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
