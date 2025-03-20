import 'package:flutter/material.dart';
import 'package:invoicegenerator/services/pdf_service.dart';
import 'package:pdf/pdf.dart';

class TemplateSelector extends StatefulWidget {
  final String initialTemplate;
  final Function(String) onTemplateSelected;

  const TemplateSelector({
    Key? key,
    required this.initialTemplate,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  State<TemplateSelector> createState() => _TemplateSelectorState();
}

class _TemplateSelectorState extends State<TemplateSelector> {
  late String _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            'SELECT TEMPLATE',
            style: TextStyle(
              fontFamily: 'Victor Mono',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF778682),
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: PdfTemplate.allTemplates.length,
            itemBuilder: (context, index) {
              final template = PdfTemplate.allTemplates[index];
              final isSelected = template.name == _selectedTemplate;

              // Convert PdfColor to Flutter Color
              final themeColor = _pdfColorToFlutterColor(template.themeColor);
              final backgroundColor = _pdfColorToFlutterColor(
                template.backgroundColor,
              );
              final dividerColor = _pdfColorToFlutterColor(
                template.dividerColor,
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTemplate = template.name;
                  });
                  widget.onTemplateSelected(template.name);
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: isSelected ? themeColor : const Color(0xFFCAD5D2),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Color preview
                      Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Divider preview
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Template name
                      Text(
                        template.name,
                        style: TextStyle(
                          fontFamily: 'Helvetica Now Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: themeColor,
                        ),
                      ),
                      // Selected indicator
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
                              fontFamily: 'Victor Mono',
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to convert PdfColor to Flutter Color
  Color _pdfColorToFlutterColor(PdfColor pdfColor) {
    return Color.fromARGB(
      255,
      (pdfColor.red * 255).round(),
      (pdfColor.green * 255).round(),
      (pdfColor.blue * 255).round(),
    );
  }
}
