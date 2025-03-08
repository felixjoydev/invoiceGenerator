import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';

class TextInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String? value;
  final bool isRequired;
  final bool isReadOnly;
  final bool isPassword;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLines;
  final TextAlign textAlign;
  final FocusNode? focusNode;

  const TextInput({
    super.key,
    required this.label,
    this.placeholder,
    this.value,
    this.isRequired = false,
    this.isReadOnly = false,
    this.isPassword = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.textAlign = TextAlign.right,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? value : null,
      focusNode: focusNode,
      obscureText: isPassword,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: textAlign,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: Theme.of(context).textTheme.labelMedium,
        alignLabelWithHint: true,
        hintText: placeholder,
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        isDense: true,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
