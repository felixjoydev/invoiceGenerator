import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:invoicegenerator/bottom_sheets/settings/business_details.dart';
import 'package:invoicegenerator/bottom_sheets/settings/invoice_settings.dart';
import 'package:invoicegenerator/services/auth_provider.dart';
import 'package:invoicegenerator/screens/auth/get-started.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Show the bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsScreen(),
    );
  }

  // Navigate to business details
  void _navigateToBusinessDetails(BuildContext context) {
    // Close current sheet and open business details
    Navigator.pop(context);
    // Show business details sheet
    showBusinessDetailsSheet(context);
  }

  // Navigate to invoice settings
  void _navigateToInvoiceSettings(BuildContext context) {
    // Close current sheet and open invoice settings
    Navigator.pop(context);
    // Show invoice settings sheet
    showInvoiceSettingsSheet(context);
  }

  // Navigate to client settings
  void _navigateToClientSettings(BuildContext context) {
    // Close current sheet and open client settings
    Navigator.pop(context);
    // TODO: Show client settings sheet
  }

  // Handle logout
  void _handleLogout(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Close bottom sheet
      Navigator.pop(context);

      // Call signOut method from AuthProvider
      await AuthProvider.of(context).signOut();

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const GetStartedScreen()),
        (route) => false,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum height (screen height - 120px)
    final double maxHeight = MediaQuery.of(context).size.height - 120;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: SizedBox(
        height: maxHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle
            Container(
              width: 48,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF373C3A),
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            const SizedBox(height: 12),
            // Main content
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFDAE4E1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: MainHeading.settings(),
                    ),

                    const SizedBox(height: 32),

                    // Settings Links
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Company Details Link
                          LinksWidget(
                            iconPath: 'assets/icons/company.svg',
                            title: 'Company Details',
                            onTap: () => _navigateToBusinessDetails(context),
                          ),

                          const SizedBox(height: 16),
                          const DashedDivider(),
                          const SizedBox(height: 16),

                          // Invoice Settings Link
                          LinksWidget(
                            iconPath: 'assets/icons/invoice.svg',
                            title: 'Invoice Settings',
                            onTap: () => _navigateToInvoiceSettings(context),
                          ),

                          const SizedBox(height: 16),
                          const DashedDivider(),
                          const SizedBox(height: 16),

                          // Client Settings Link
                          LinksWidget(
                            iconPath: 'assets/icons/clients.svg',
                            title: 'Client Settings',
                            onTap: () => _navigateToClientSettings(context),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Logout Section at the bottom
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: GestureDetector(
                        onTap: () => _handleLogout(context),
                        child: const LogoutSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LinksWidget extends StatelessWidget {
  final String? iconPath;
  final String title;
  final VoidCallback onTap;

  const LinksWidget({
    super.key,
    this.iconPath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 24,
        color:
            Colors.transparent, // Using transparent to keep the original design
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon - either SVG or custom icon
                if (iconPath != null)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      iconPath!,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF373C3A),
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                else
                  const BuildingsIcon(),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF373C3A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Helvetica Now Display',
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                'assets/icons/chevron-right.svg',
                colorFilter: const ColorFilter.mode(
                  Color(0xFF373C3A),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BuildingsIcon extends StatelessWidget {
  const BuildingsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: BuildingsPainter()),
    );
  }
}

class BuildingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Color(0xFF373C3A)
          ..style = PaintingStyle.fill;

    // Draw all rectangles that make up the buildings icon
    // Rectangle 2278
    canvas.drawRect(Rect.fromLTWH(4, 2, 10, 2), paint);

    // Rectangle 2279
    canvas.drawRect(Rect.fromLTWH(4, 20, 10, 2), paint);

    // Rectangle 2297
    canvas.drawRect(Rect.fromLTWH(16, 20, 4, 2), paint);

    // Rectangle 2280
    canvas.drawRect(Rect.fromLTWH(2, 2, 2, 20), paint);

    // Rectangle 2281
    canvas.drawRect(Rect.fromLTWH(14, 2, 2, 20), paint);

    // Rectangle 2282
    canvas.drawRect(Rect.fromLTWH(6, 6, 2, 2), paint);

    // Rectangle 2283
    canvas.drawRect(Rect.fromLTWH(10, 6, 2, 2), paint);

    // Rectangle 2285
    canvas.drawRect(Rect.fromLTWH(6, 10, 2, 2), paint);

    // Rectangle 2286
    canvas.drawRect(Rect.fromLTWH(10, 10, 2, 2), paint);

    // Rectangle 2288
    canvas.drawRect(Rect.fromLTWH(6, 14, 2, 2), paint);

    // Rectangle 2289
    canvas.drawRect(Rect.fromLTWH(10, 14, 2, 2), paint);

    // Rectangle 2292
    canvas.drawRect(Rect.fromLTWH(16, 6, 4, 2), paint);

    // Rectangle 2293
    canvas.drawRect(Rect.fromLTWH(20, 6, 2, 16), paint);

    // Rectangle 2294
    canvas.drawRect(Rect.fromLTWH(16, 10, 2, 2), paint);

    // Rectangle 2295
    canvas.drawRect(Rect.fromLTWH(16, 14, 2, 2), paint);

    // Rectangle 2296
    canvas.drawRect(Rect.fromLTWH(16, 18, 2, 2), paint);

    // Rectangle 2291
    canvas.drawRect(Rect.fromLTWH(6, 18, 6, 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final width = constraints.constrainWidth();
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount = (width / (dashWidth + dashSpace)).floor();

          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFCAD5D2)),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class LogoutSection extends StatelessWidget {
  const LogoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 362,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 4,
                  color: Color.fromRGBO(202, 213, 210, 1),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomLogoutIcon(
                width: 24,
                height: 24,
                color: Color.fromRGBO(55, 60, 58, 1),
              ),
              SizedBox(width: 7),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromRGBO(55, 60, 58, 1),
                  fontSize: 16,
                  fontFamily: 'Helvetica Now Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomLogoutIcon extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const CustomLogoutIcon({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: LogoutIconPainter(color: color)),
    );
  }
}

class LogoutIconPainter extends CustomPainter {
  final Color color;

  LogoutIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw the frame
    // Top horizontal line
    canvas.drawRect(Rect.fromLTWH(3, 3, 18, 2), paint);

    // Left vertical line
    canvas.drawRect(Rect.fromLTWH(3, 3, 2, 18), paint);

    // Bottom horizontal line
    canvas.drawRect(Rect.fromLTWH(3, 19, 18, 2), paint);

    // Top right corner
    canvas.drawRect(Rect.fromLTWH(19, 3, 2, 4), paint);

    // Bottom right corner
    canvas.drawRect(Rect.fromLTWH(19, 17, 2, 4), paint);

    // Arrow horizontal line
    canvas.drawRect(Rect.fromLTWH(7, 11, 14, 2), paint);

    // Arrow head parts
    canvas.drawRect(Rect.fromLTWH(17, 9, 2, 2), paint);
    canvas.drawRect(Rect.fromLTWH(15, 7, 2, 2), paint);
    canvas.drawRect(Rect.fromLTWH(17, 13, 2, 2), paint);
    canvas.drawRect(Rect.fromLTWH(15, 15, 2, 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
