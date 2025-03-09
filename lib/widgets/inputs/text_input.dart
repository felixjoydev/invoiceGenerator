import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';

class BusinessNameField extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const BusinessNameField({Key? key, this.controller, this.onChanged})
    : super(key: key);

  @override
  State<BusinessNameField> createState() => _BusinessNameFieldState();
}

class _BusinessNameFieldState extends State<BusinessNameField> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'BUSINESS NAME',
                style: TextStyle(
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF373C3A),
                ),
              ),
              Expanded(
                child: Focus(
                  onFocusChange: (hasFocus) {
                    setState(() {
                      _hasFocus = hasFocus;
                    });
                  },
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'Enter business name',
                      hintStyle: TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 16,
                        color: Color(0xFF8D9694),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Helvetica Now Display',
                      fontSize: 16,
                      color: Color(0xFF373C3A),
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          painter: DashedLinePainter(
            color:
                _hasFocus ? const Color(0xFF373C3A) : const Color(0xFFCAD5D2),
          ),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}

/// A generic text input field based on the BusinessNameField pattern
class GenericInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onBlur;
  final String? errorText;
  final TextStyle? errorStyle;
  final Alignment? errorAlignment;

  const GenericInputField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onBlur,
    this.errorText,
    this.errorStyle,
    this.errorAlignment,
  }) : super(key: key);

  @override
  State<GenericInputField> createState() => _GenericInputFieldState();
}

class _GenericInputFieldState extends State<GenericInputField> {
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
            Container(
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
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textAlign: TextAlign.right,
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
                        errorText: null, // We handle error text separately
                      ),
                      style: TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 16,
                        color: hasError ? Colors.red : const Color(0xFF373C3A),
                      ),
                      onChanged: widget.onChanged,
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

/// A specialized input field for phone numbers that only allows numeric input
class PhoneInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onBlur;
  final String? errorText;
  final TextStyle? errorStyle;
  final Alignment? errorAlignment;

  const PhoneInputField({
    Key? key,
    this.label = 'PHONE',
    this.hintText = 'Enter your phone number',
    this.controller,
    this.onChanged,
    this.onBlur,
    this.errorText,
    this.errorStyle,
    this.errorAlignment,
  }) : super(key: key);

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _controller;
  bool _hasFocus = false;
  final FocusNode _focusNode = FocusNode();
  String? _localErrorText;

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

      if (!_focusNode.hasFocus) {
        _validatePhone();
        if (widget.onBlur != null) {
          widget.onBlur!();
        }
      }
    }
  }

  void _validatePhone() {
    final value = _controller.text;
    setState(() {
      if (value.isEmpty) {
        _localErrorText = null;
        return;
      }

      // Basic phone validation - at least 6 digits
      final RegExp phoneRegex = RegExp(r'^[0-9]{6,}$');
      _localErrorText = phoneRegex.hasMatch(value) 
          ? null 
          : 'Please enter a valid phone number';
    });
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
    final bool hasError = widget.errorText != null || _localErrorText != null;
    final String? displayErrorText = widget.errorText ?? _localErrorText;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.phone, // Use phone keyboard
                      // Only allow digits
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        errorText: null, // We handle error text separately
                      ),
                      style: TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 16,
                        color: hasError ? Colors.red : const Color(0xFF373C3A),
                      ),
                      onChanged: (value) {
                        // Clear error when typing
                        if (_localErrorText != null) {
                          setState(() {
                            _localErrorText = null;
                          });
                        }
                        if (widget.onChanged != null) {
                          widget.onChanged!(value);
                        }
                      },
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
        if (displayErrorText != null)
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: Container(
              alignment: widget.errorAlignment ?? Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                displayErrorText,
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