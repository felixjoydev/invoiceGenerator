import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home icon
          InkWell(
            onTap: () => onItemSelected(BottomNavItem.home),
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

          // Invoice icon
          InkWell(
            onTap: () => onItemSelected(BottomNavItem.invoice),
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

          // Add button
          InkWell(
            onTap: onAddTapped,
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

          // Clients icon
          InkWell(
            onTap: () => onItemSelected(BottomNavItem.clients),
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

          // Catalog icon
          InkWell(
            onTap: () => onItemSelected(BottomNavItem.catalog),
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
        ],
      ),
    );
  }
}
