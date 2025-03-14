import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';

class DateInput extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onBlur;
  final String? errorText;
  final TextStyle? errorStyle;
  final Alignment? errorAlignment;
  final bool readOnly;

  const DateInput({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onBlur,
    this.errorText,
    this.errorStyle,
    this.errorAlignment,
    this.readOnly = false,
  });

  @override
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  late TextEditingController _controller;
  bool _hasFocus = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });

      if (!_focusNode.hasFocus && widget.onBlur != null) {
        widget.onBlur!();
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Victor Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF373C3A),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTap,
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                readOnly: widget.readOnly,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.datetime,
                                // Format input as DD/MM/YYYY
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9/]'),
                                  ),
                                  LengthLimitingTextInputFormatter(10),
                                  _DateInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  hintStyle: TextStyle(
                                    fontFamily: 'Helvetica Now Display',
                                    fontSize: 16,
                                    color:
                                        hasError
                                            ? Colors.red.withOpacity(0.7)
                                            : const Color(0xFF8D9694),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  errorText:
                                      null, // We handle error text separately
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Helvetica Now Display',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF373C3A),
                                ),
                                onChanged: widget.onChanged,
                                onTap: widget.onTap,
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Calendar icon
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CustomPaint(
                                painter: CalendarIconPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              painter: DashedLinePainter(
                color:
                    hasError
                        ? Colors.red
                        : (_hasFocus
                            ? const Color(0xFF373C3A)
                            : const Color(0xFFCAD5D2)),
              ),
              size: Size(MediaQuery.of(context).size.width, 1),
            ),
          ],
        ),
        if (widget.errorText != null)
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: Container(
              alignment: widget.errorAlignment ?? Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.errorText!,
                style:
                    widget.errorStyle ??
                    const TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 12,
                      color: Colors.red,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

// Custom formatter for DD/MM/YYYY format
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is less than the old, it means the user is deleting
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String newText = newValue.text;
    int selectionIndex = newValue.selection.end;

    // Validate month value (cannot exceed 12)
    if (newText.length == 4 && newText.contains('/')) {
      // User is entering the month
      String monthPart = newText.substring(
        3,
      ); // Get month digits entered so far
      if (monthPart.isNotEmpty) {
        int? monthValue = int.tryParse(monthPart);
        // If it's a single digit greater than 1, it's valid (as it could become 10, 11, 12)
        // If it's two digits and exceeds 12, it's invalid
        if (monthValue != null) {
          if (monthPart.length == 1 && monthValue > 1) {
            // Single digit > 1 is allowed (could become 10-12)
          } else if (monthValue > 12) {
            // Don't allow input that makes month > 12
            return oldValue;
          }
        }
      }
    } else if (newText.length == 5 && newText.contains('/')) {
      // User has entered a full month (MM)
      String monthPart = newText.substring(3, 5); // Extract MM
      int? monthValue = int.tryParse(monthPart);
      if (monthValue != null && monthValue > 12) {
        // Don't allow month > 12
        return oldValue;
      }
    }

    // Add slashes automatically after day and month
    if (newText.length == 2 && !newText.contains('/')) {
      newText = '$newText/';
      selectionIndex++;
    } else if (newText.length == 5 && !newText.substring(3).contains('/')) {
      newText = '$newText/';
      selectionIndex++;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

// Custom calendar icon painter to match the SVG design
class CalendarIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF373C3A)
          ..style = PaintingStyle.fill;

    final path = Path();

    // Draw calendar outline
    path.moveTo(15, 2); // Start at top center
    path.lineTo(17, 2); // Top right corner
    path.lineTo(17, 4);
    path.lineTo(19, 4);
    path.lineTo(21, 4);
    path.lineTo(21, 6);
    path.lineTo(21, 8);
    path.lineTo(21, 10);
    path.lineTo(21, 20);
    path.lineTo(21, 22);
    path.lineTo(19, 22);
    path.lineTo(5, 22);
    path.lineTo(3, 22);
    path.lineTo(3, 20);
    path.lineTo(3, 10);
    path.lineTo(3, 8);
    path.lineTo(3, 6);
    path.lineTo(3, 4);
    path.lineTo(5, 4);
    path.lineTo(7, 4);
    path.lineTo(7, 2);
    path.lineTo(9, 2);
    path.lineTo(9, 4);
    path.lineTo(15, 4);
    path.lineTo(15, 2);
    path.close();

    // Top section
    path.moveTo(9, 6);
    path.lineTo(7, 6);
    path.lineTo(5, 6);
    path.lineTo(5, 8);
    path.lineTo(19, 8);
    path.lineTo(19, 6);
    path.lineTo(17, 6);
    path.lineTo(15, 6);
    path.lineTo(9, 6);
    path.close();

    // Main calendar body
    path.moveTo(5, 10);
    path.lineTo(5, 20);
    path.lineTo(19, 20);
    path.lineTo(19, 10);
    path.lineTo(5, 10);
    path.close();

    // Calendar grid rows
    // Row 1
    path.moveTo(7, 12);
    path.lineTo(9, 12);
    path.lineTo(9, 14);
    path.lineTo(7, 14);
    path.lineTo(7, 12);
    path.close();

    path.moveTo(13, 12);
    path.lineTo(11, 12);
    path.lineTo(11, 14);
    path.lineTo(13, 14);
    path.lineTo(13, 12);
    path.close();

    path.moveTo(15, 12);
    path.lineTo(17, 12);
    path.lineTo(17, 14);
    path.lineTo(15, 14);
    path.lineTo(15, 12);
    path.close();

    // Row 2
    path.moveTo(9, 16);
    path.lineTo(7, 16);
    path.lineTo(7, 18);
    path.lineTo(9, 18);
    path.lineTo(9, 16);
    path.close();

    path.moveTo(11, 16);
    path.lineTo(13, 16);
    path.lineTo(13, 18);
    path.lineTo(11, 18);
    path.lineTo(11, 16);
    path.close();

    path.moveTo(17, 16);
    path.lineTo(15, 16);
    path.lineTo(15, 18);
    path.lineTo(17, 18);
    path.lineTo(17, 16);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
