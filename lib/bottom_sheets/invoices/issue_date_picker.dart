import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/inputs/calendar_input.dart';

class IssueDatePickerSheet extends StatefulWidget {
  final Function(DateTime?)? onDateSelected;
  final DateTime? initialDate;

  const IssueDatePickerSheet({
    super.key,
    this.onDateSelected,
    this.initialDate,
  });

  @override
  State<IssueDatePickerSheet> createState() => _IssueDatePickerSheetState();
}

class _IssueDatePickerSheetState extends State<IssueDatePickerSheet> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize with the current date passed from parent
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
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
          // Main content in a SingleChildScrollView to handle potential overflow
          Flexible(
            child: SingleChildScrollView(
              child: Container(
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
                    // Header with calendar icon
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: SvgPicture.asset(
                            'assets/icons/calendar.svg',
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF373C3A),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Issue Date',
                          style: const TextStyle(
                            color: Color(0xFF373C3A),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Helvetica Now Display',
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

                    SizedBox(height: 24),

                    // Calendar input
                    CalendarInput(
                      initialDate: _selectedDate,
                      onDateSelected: _onDateSelected,
                    ),

                    SizedBox(height: 32),

                    // Select button
                    PrimaryButton(
                      label: 'SELECT',
                      onPressed: () {
                        if (widget.onDateSelected != null) {
                          widget.onDateSelected!(_selectedDate);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper method to show the IssueDatePickerSheet as a modal bottom sheet
void showIssueDatePicker(
  BuildContext context, {
  Function(DateTime?)? onDateSelected,
  DateTime? initialDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: IssueDatePickerSheet(
          onDateSelected: onDateSelected,
          initialDate: initialDate,
        ),
      );
    },
  );
}
