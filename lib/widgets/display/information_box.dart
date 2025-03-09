import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InformationBox extends StatelessWidget {
  const InformationBox({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 365,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 362,
            height: 4,
            color: const Color.fromRGBO(202, 213, 210, 1),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/dashboard.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 239,
                  child: Text(
                    'Your dashboard will appear once you add more data',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'HelveticaNowDisplay',
                      letterSpacing: -0.5,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
