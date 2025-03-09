import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeAction extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String description;
  final VoidCallback onAddPressed;

  const WelcomeAction({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side with icon and text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon - aligned with the top text
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: SvgPicture.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF373C3A),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Title and description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF373C3A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 16,
                      color: Color(0xFF8D9694),
                      letterSpacing: -0.2,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Add button using the SVG asset
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: GestureDetector(
              onTap: onAddPressed,
              child: SvgPicture.asset(
                'assets/icons/big-add.svg',
                width: 42,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeActionsList extends StatelessWidget {
  final VoidCallback? onInvoicePressed;
  final VoidCallback? onClientPressed;
  final VoidCallback? onCatalogPressed;

  const WelcomeActionsList({
    super.key,
    this.onInvoicePressed,
    this.onClientPressed,
    this.onCatalogPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Invoices action
        WelcomeAction(
          iconAsset: 'assets/icons/invoice.svg',
          title: 'INVOICES',
          description: 'Create your first invoice',
          onAddPressed:
              onInvoicePressed ??
              () {
                // Default navigation to invoice creation screen
                print('Navigate to invoice creation screen');
              },
        ),

        // Divider with padding
        SizedBox(height: 24),
        Divider(height: 1, thickness: 1, color: Color(0xFFCAD5D2)),
        SizedBox(height: 24),

        // Clients action
        WelcomeAction(
          iconAsset: 'assets/icons/clients.svg',
          title: 'CLIENTS',
          description: 'Add your first client',
          onAddPressed:
              onClientPressed ??
              () {
                // Default navigation to add client screen
                print('Navigate to add client screen');
              },
        ),

        // Divider with padding
        SizedBox(height: 24),
        Divider(height: 1, thickness: 1, color: Color(0xFFCAD5D2)),
        SizedBox(height: 24),

        // Catalog action
        WelcomeAction(
          iconAsset: 'assets/icons/catalog-black.svg',
          title: 'CATALOG',
          description: 'Add your first catalog item',
          onAddPressed:
              onCatalogPressed ??
              () {
                // Default navigation to create catalog item screen
                print('Navigate to create catalog item screen');
              },
        ),
      ],
    );
  }
}

// Factory methods for creating specific action cards
class WelcomeActions {
  static WelcomeAction invoices({required VoidCallback onAddPressed}) {
    return WelcomeAction(
      iconAsset: 'assets/icons/invoice.svg',
      title: 'INVOICES',
      description: 'Create your first invoice',
      onAddPressed: onAddPressed,
    );
  }

  static WelcomeAction clients({required VoidCallback onAddPressed}) {
    return WelcomeAction(
      iconAsset: 'assets/icons/clients.svg',
      title: 'CLIENTS',
      description: 'Add your first client',
      onAddPressed: onAddPressed,
    );
  }

  static WelcomeAction catalog({required VoidCallback onAddPressed}) {
    return WelcomeAction(
      iconAsset: 'assets/icons/catalog-black.svg',
      title: 'CATALOG',
      description: 'Add your first catalog item',
      onAddPressed: onAddPressed,
    );
  }
}
