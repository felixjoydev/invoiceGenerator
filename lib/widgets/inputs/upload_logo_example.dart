import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

/// An improved version of the UploadLogoSection using the AppIcon widget
class UploadLogoSectionImproved extends StatelessWidget {
  const UploadLogoSectionImproved({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPLOAD LOGO',
                      style: TextStyle(
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF373C3A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREFERRED IMAGE SIZE',
                          style: TextStyle(
                            fontFamily: 'Victor Mono',
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            color: Color(0xFF8D9694),
                          ),
                        ),
                        Text(
                          '240px x 240px @72 DPI',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                        Text(
                          'Max size of 1MB',
                          style: TextStyle(
                            fontFamily: 'Helvetica Now Display',
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: Color(0xFF373C3A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  height: 24,
                  child: Row(
                    children: [
                      // Using the AppIcon widget instead of CustomPaint
                      AppIcon(
                        iconType: IconType.upload,
                        size: 24,
                        color: Color(0xFFF05022),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'UPLOAD',
                        style: TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFF05022),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(height: 1, color: Color(0xFFCAD5D2)),
        ],
      ),
    );
  }
}
