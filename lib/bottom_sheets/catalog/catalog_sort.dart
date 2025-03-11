import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CatalogSortSheet extends StatefulWidget {
  final Function(int?)? onSortSelected;

  const CatalogSortSheet({super.key, this.onSortSelected});

  @override
  State<CatalogSortSheet> createState() => _CatalogSortSheetState();
}

class _CatalogSortSheetState extends State<CatalogSortSheet> {
  int? _selectedOption;

  void _clearSelection() {
    setState(() {
      _selectedOption = null;
    });

    // Return null to indicate clearing the sort and close the sheet
    if (widget.onSortSelected != null) {
      widget.onSortSelected!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Handle
          Container(
            width: 48,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xFF373C3A),
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          SizedBox(height: 12),
          // Main content
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            color: Color(0xFFDAE4E1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Clear button
                MainHeadingWithClear(
                  text: 'Sort Catalog',
                  iconPath: 'assets/icons/sort.svg',
                  onClearPressed: _clearSelection,
                ),

                SizedBox(height: 24),

                // Sort options
                Column(
                  children: [
                    // Option 1
                    SortOption(
                      title: 'Amount (Low to High)',
                      isSelected: _selectedOption == 0,
                      onTap: () {
                        setState(() {
                          _selectedOption = _selectedOption == 0 ? null : 0;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DashedDivider(),
                    SizedBox(height: 16),

                    // Option 2
                    SortOption(
                      title: 'Amount (High to Low)',
                      isSelected: _selectedOption == 1,
                      onTap: () {
                        setState(() {
                          _selectedOption = _selectedOption == 1 ? null : 1;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DashedDivider(),
                    SizedBox(height: 16),

                    // Option 3
                    SortOption(
                      title: 'Item Name (Ascending)',
                      isSelected: _selectedOption == 2,
                      onTap: () {
                        setState(() {
                          _selectedOption = _selectedOption == 2 ? null : 2;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DashedDivider(),
                    SizedBox(height: 16),

                    // Option 4
                    SortOption(
                      title: 'Item Name (Descending)',
                      isSelected: _selectedOption == 3,
                      onTap: () {
                        setState(() {
                          _selectedOption = _selectedOption == 3 ? null : 3;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 40),

                // Save button
                PrimaryButton(
                  label: 'SAVE',
                  onPressed: () {
                    if (widget.onSortSelected != null) {
                      widget.onSortSelected!(_selectedOption);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// MainHeading with a CLEAR button on the right
class MainHeadingWithClear extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onClearPressed;

  const MainHeadingWithClear({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title with icon on left
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF373C3A),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF373C3A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Helvetica Now Display',
                  ),
                ),
              ],
            ),

            // Clear button on right
            GestureDetector(
              onTap: onClearPressed,
              child: Text(
                'CLEAR',
                style: TextStyle(
                  color: Color(0xFFF05022),
                  fontSize: 14,
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: double.infinity,
          color: const Color(0xFFCAD5D2),
        ),
      ],
    );
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

class SortOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SortOption({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24,
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Helvetica Now Display',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SvgPicture.asset(
              isSelected
                  ? 'assets/icons/checked.svg'
                  : 'assets/icons/unchecked.svg',
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
