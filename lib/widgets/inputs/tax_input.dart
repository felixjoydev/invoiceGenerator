import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/inputs/toggle.dart';
import 'package:flutter/services.dart';

class TaxInputRow extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool enabled;
  final Function(bool)? onToggle;

  const TaxInputRow({
    Key? key,
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.onToggle,
  }) : super(key: key);

  @override
  State<TaxInputRow> createState() => _TaxInputRowState();
}

class _TaxInputRowState extends State<TaxInputRow> {
  late TextEditingController _controller;
  bool _hasFocus = false;
  final FocusNode _focusNode = FocusNode();
  bool _previousEnabledState = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _previousEnabledState = widget.enabled;

    // Add listener to handle formatting and validation
    _controller.addListener(_handleTextChange);

    // Add focus listener to track focus state
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;

        // If focus is lost and the field is empty, make sure it's completely empty
        // This ensures the placeholder will show
        if (!_focusNode.hasFocus &&
            (_controller.text == '%' || _controller.text.isEmpty)) {
          _controller.text = '';
        }
      });
    });
  }

  @override
  void didUpdateWidget(TaxInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle toggle state changes
    if (oldWidget.enabled != widget.enabled) {
      // When toggling, reset focus state and unfocus if needed
      setState(() {
        if (!widget.enabled) {
          // If being disabled, remove focus
          _hasFocus = false;
          _focusNode.unfocus();
        } else if (widget.enabled && !_previousEnabledState) {
          // If being re-enabled, ensure border is not focused
          _hasFocus = false;
          _focusNode.unfocus();

          // When re-enabling, clear text if it's just a % or empty
          // to ensure placeholder shows correctly
          if (_controller.text == '%' || _controller.text.isEmpty) {
            _controller.text = '';
          }
        }

        _previousEnabledState = widget.enabled;
      });
    }
  }

  void _handleTextChange() {
    final text = _controller.text;

    // If empty, don't process further
    if (text.isEmpty) return;

    // Skip processing if the text already ends with %
    if (text.endsWith('%')) return;

    // Remove any non-numeric characters except decimal point
    String numericText = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Ensure only one decimal point
    if (numericText.contains('.')) {
      final parts = numericText.split('.');
      if (parts.length > 2) {
        numericText = '${parts[0]}.${parts[1]}';
      }
    }

    // Limit to 100
    double? value = double.tryParse(numericText);
    if (value != null && value > 100) {
      numericText = '100';
    }

    // Only update if the value has changed to avoid infinite loop
    if (numericText != text.replaceAll('%', '')) {
      final cursorPosition = _controller.selection.start;
      final textLengthDifference = (numericText.length + 1) - text.length;

      _controller.text = numericText.isEmpty ? '' : '$numericText%';

      // Maintain cursor position
      if (cursorPosition != -1 && numericText.isNotEmpty) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + textLengthDifference),
        );
      }
    } else if (!text.endsWith('%') && numericText.isNotEmpty) {
      // Just add the % if it's missing and there's a value
      final cursorPosition = _controller.selection.start;
      _controller.text = '$text%';

      // Keep cursor before the %
      if (cursorPosition != -1) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition),
        );
      }
    }

    // Notify parent of change
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define identical text styles to ensure perfect consistency
    const TextStyle inputTextStyle = TextStyle(
      fontFamily: 'Helvetica Now Display',
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      height: 1.0,
      color: Color(0xFF373C3A),
    );

    const TextStyle placeholderStyle = TextStyle(
      fontFamily: 'Helvetica Now Display',
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      height: 1.0,
      color: Color(0xFF8D9694),
    );

    const TextStyle disabledStyle = TextStyle(
      fontFamily: 'Helvetica Now Display',
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      height: 1.0,
      color: Color(0xFFB6BAC0),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "TAX",
                style: TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF373C3A),
                ),
              ),
              const SizedBox(width: 12),
              CustomCheckbox(
                isChecked: widget.enabled,
                onChanged: widget.onToggle,
              ),
              Expanded(
                child:
                    widget.enabled
                        ? TextField(
                          focusNode: _focusNode,
                          controller: _controller,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onTap: () {
                            // When tapped, explicitly set focus state
                            setState(() {
                              _hasFocus = true;
                            });
                          },
                          onEditingComplete: () {
                            // Handle when editing is done but focus isn't necessarily lost
                            if (_controller.text == '%' ||
                                _controller.text.isEmpty) {
                              _controller.text = '';
                            }
                            FocusScope.of(context).unfocus();
                          },
                          inputFormatters: [
                            // This formatter will prevent values above 100
                            TextInputFormatter.withFunction((
                              oldValue,
                              newValue,
                            ) {
                              // Allow empty values
                              if (newValue.text.isEmpty ||
                                  newValue.text == '%') {
                                return newValue;
                              }

                              // Process the text without the % symbol
                              String textWithoutPercent = newValue.text
                                  .replaceAll('%', '');

                              // Try to parse as a number
                              double? value = double.tryParse(
                                textWithoutPercent,
                              );

                              // If we can't parse it or it's above 100, reject or modify
                              if (value == null) {
                                return oldValue;
                              }

                              if (value > 100) {
                                String newText = '100%';
                                return TextEditingValue(
                                  text: newText,
                                  selection: TextSelection.collapsed(
                                    offset: newText.length - 1,
                                  ),
                                );
                              }

                              return newValue;
                            }),
                            // Also keep the original formatter to allow only numbers and dots
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.%]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            hintText: "Enter tax %",
                            hintStyle: placeholderStyle,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: inputTextStyle,
                          onChanged: (value) {
                            // Let the listener handle formatting
                          },
                        )
                        : Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.zero,
                          child: const Text(
                            "Enter tax %",
                            textAlign: TextAlign.right,
                            style: disabledStyle,
                          ),
                        ),
              ),
            ],
          ),
        ),
        CustomPaint(
          painter: DashedLinePainter(
            color:
                widget.enabled
                    ? (_hasFocus
                        ? const Color(0xFF373C3A)
                        : const Color(0xFFCAD5D2))
                    : const Color(0xFFCAD5D2),
          ),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({this.color = const Color(0xFFCAD5D2)});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5;
    double dashSpace = 3;
    double startX = 0;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
