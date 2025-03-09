import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/theme/app_theme.dart';

enum BottomNavItem { home, invoice, add, clients, catalog }

class BottomNav extends StatelessWidget {
  final BottomNavItem activeItem;
  final ValueChanged<BottomNavItem> onItemSelected;
  final VoidCallback onAddTapped;

  const BottomNav({
    super.key,
    required this.activeItem,
    required this.onItemSelected,
    required this.onAddTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 100,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 48),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home icon with increased touch area
          Material(
            color: Colors.transparent,
            child: Ink(
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onItemSelected(BottomNavItem.home);
                },
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                // Extend hit test area with no visual change
                hoverColor: Colors.transparent,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        activeItem == BottomNavItem.home
                            ? 'assets/icons/home-selected.svg'
                            : 'assets/icons/home.svg',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Invoice icon with increased touch area
          Material(
            color: Colors.transparent,
            child: Ink(
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onItemSelected(BottomNavItem.invoice);
                },
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        activeItem == BottomNavItem.invoice
                            ? 'assets/icons/invoice-selected.svg'
                            : 'assets/icons/invoice.svg',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Add button with increased touch area
          Material(
            color: Colors.transparent,
            child: Ink(
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onAddTapped();
                },
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 42,
                      height: 24,
                      child: SvgPicture.asset(
                        activeItem == BottomNavItem.add
                            ? 'assets/icons/big-close.svg'
                            : 'assets/icons/big-add-black.svg',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Clients icon with increased touch area
          Material(
            color: Colors.transparent,
            child: Ink(
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onItemSelected(BottomNavItem.clients);
                },
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        activeItem == BottomNavItem.clients
                            ? 'assets/icons/clients-selected.svg'
                            : 'assets/icons/clients.svg',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Catalog icon with increased touch area
          Material(
            color: Colors.transparent,
            child: Ink(
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onItemSelected(BottomNavItem.catalog);
                },
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        activeItem == BottomNavItem.catalog
                            ? 'assets/icons/catalog-selected.svg'
                            : 'assets/icons/catalog-black.svg',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
