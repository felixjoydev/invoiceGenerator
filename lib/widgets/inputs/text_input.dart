import 'package:flutter/material.dart';
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
  final String? errorText;

  const GenericInputField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  State<GenericInputField> createState() => _GenericInputFieldState();
}

class _GenericInputFieldState extends State<GenericInputField> {
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
                child: Focus(
                  onFocusChange: (hasFocus) {
                    setState(() {
                      _hasFocus = hasFocus;
                    });
                  },
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 16,
                        color: Color(0xFF8D9694),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      errorText: widget.errorText,
                      errorStyle: const TextStyle(
                        fontFamily: 'Helvetica Now Display',
                        fontSize: 12,
                        color: Colors.red,
                      ),
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
                widget.errorText != null
                    ? Colors.red
                    : (_hasFocus
                        ? const Color(0xFF373C3A)
                        : const Color(0xFFCAD5D2)),
          ),
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
      ],
    );
  }
}
