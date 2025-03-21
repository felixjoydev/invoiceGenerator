import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';
import 'package:invoicegenerator/services/image_service.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';
import 'package:invoicegenerator/widgets/display/MainHeading.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UploadLogoSection extends StatefulWidget {
  final Function(String path)? onLogoSelected;
  final String? initialLogoPath;
  final Function()? onLogoRemoved;

  const UploadLogoSection({
    super.key,
    this.onLogoSelected,
    this.initialLogoPath,
    this.onLogoRemoved,
  });

  @override
  State<UploadLogoSection> createState() => _UploadLogoSectionState();
}

class _UploadLogoSectionState extends State<UploadLogoSection> {
  final ImageService _imageService = ImageService();
  String? _logoPath;
  bool _isLoading = false;
  String? _errorMessage;

  // Show detailed logs to help with debugging
  void _showLogDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Debug Logs'),
            content: SingleChildScrollView(
              child: SelectableText(_imageService.getErrorLogs()),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _imageService.getErrorLogs()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs copied to clipboard')),
                  );
                },
                child: const Text('COPY'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _logoPath = widget.initialLogoPath;
    debugPrint('UploadLogoSection initialized with logo path: $_logoPath');
  }

  @override
  void didUpdateWidget(UploadLogoSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the initialLogoPath changes, update our local path
    if (widget.initialLogoPath != oldWidget.initialLogoPath) {
      debugPrint(
        'UploadLogoSection initialLogoPath changed from ${oldWidget.initialLogoPath} to ${widget.initialLogoPath}',
      );
      setState(() {
        _logoPath = widget.initialLogoPath;
      });
    }
  }


  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ImagePickerBottomSheet(
            onImageSourceSelected: (isPhotoLibrary) async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              try {
                final String? pickedImagePath = await _imageService.pickImage(
                  context,
                  usePhotoLibrary: isPhotoLibrary,
                );

                if (pickedImagePath != null) {
                  debugPrint('New logo selected: $pickedImagePath');
                  setState(() {
                    // If there was a previous logo and it's different from the initial one,
                    // delete it to avoid accumulating unused files
                    if (_logoPath != null &&
                        _logoPath != widget.initialLogoPath &&
                        _logoPath != pickedImagePath) {
                      // Add check to not delete if it's the same file
                      debugPrint('Deleting old logo: $_logoPath');
                      _imageService.deleteLogo(_logoPath);
                    }

                    _logoPath = pickedImagePath;
                  });

                  // Notify parent about the change
                  if (widget.onLogoSelected != null) {
                    debugPrint('Notifying parent of new logo: $_logoPath');
                    widget.onLogoSelected!(_logoPath!);
                  }
                }
              } catch (e) {
                setState(() {
                  // Clean up the error message for better user experience
                  String errorMsg = e.toString();
                  if (errorMsg.contains('Exception: ')) {
                    errorMsg = errorMsg.replaceAll('Exception: ', '');
                  }
                  _errorMessage = errorMsg;
                });
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
    );
  }

  void _removeImage() {
    debugPrint('Removing logo: $_logoPath');

    // Delete the logo file
    if (_logoPath != null) {
      _imageService.deleteLogo(_logoPath);
    }

    setState(() {
      _logoPath = null;
    });

    // Notify parent about the removal
    if (widget.onLogoRemoved != null) {
      widget.onLogoRemoved!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if logo path is valid
    bool logoExists = false;
    if (_logoPath != null) {
      final file = File(_logoPath!);
      logoExists = file.existsSync();
      debugPrint(
        'Logo exists check in build: $logoExists for path: $_logoPath',
      );

      if (!logoExists) {
        debugPrint('WARNING: Logo file does not exist, but path is not null!');
      }
    }

    // We'll always show the logo container if we have a path, even if the file doesn't exist
    // The ImageService will handle showing a placeholder if needed
    final bool showLogoContainer = _logoPath != null;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UPLOAD LOGO',
                        style: TextStyle(
                          fontFamily: 'Victor Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF373C3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PREFERRED IMAGE SIZE',
                            style: TextStyle(
                              fontFamily: 'Victor Mono',
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              color: Color(0xFF8D9694),
                            ),
                          ),
                          const Text(
                            '240px x 240px @72 DPI',
                            style: TextStyle(
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: Color(0xFF373C3A),
                            ),
                          ),
                          const Text(
                            'Max size of 1MB',
                            style: TextStyle(
                              fontFamily: 'Helvetica Now Display',
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: Color(0xFF373C3A),
                            ),
                          ),
                          if (_errorMessage != null)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontFamily: 'Helvetica Now Display',
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showLogDialog,
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? Container(
                      width: 120,
                      height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF373C3A),
                        ),
                      ),
                    )
                    : !showLogoContainer
                    ? SecondaryButton(
                      iconType: IconType.upload,
                      text: 'UPLOAD',
                      onPressed: _showImagePickerSheet,
                    )
                    : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _showImagePickerSheet,
                          child: Container(
                            width: 120,
                            height: 75,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  logoExists
                                      ? null
                                      : Border.all(color: Colors.red),
                            ),
                            child: Stack(
                              children: [
                                // Always try to show something in the logo container
                                logoExists
                                    ? Center(
                                      child: _imageService.getLogoWidget(
                                        _logoPath,
                                      ),
                                    )
                                    : Container(
                                      color: Colors.grey.withOpacity(0.1),
                                      child: Center(
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                if (!logoExists)
                                  Positioned.fill(
                                    child: Center(
                                      child: Container(
                                        color: Colors.red.withOpacity(0.3),
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Add close icon button outside the container
                        Positioned(
                          top: -10,
                          right: 0,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: SvgPicture.asset(
                              'assets/icons/close-small.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 1,
            child: CustomPaint(
              painter: DashedLinePainter(),
              size: const Size(double.infinity, 1),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomUploadIcon extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const CustomUploadIcon({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: UploadIconPainter(color: color)),
    );
  }
}

class UploadIconPainter extends CustomPainter {
  final Color color;

  UploadIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw the upload icon
    final Path path = Path();

    // Vertical line
    path.addRect(
      Rect.fromLTWH(
        size.width / 2 - 1,
        size.height / 2,
        2,
        size.height / 2 - 3,
      ),
    );

    // Horizontal line at bottom
    path.addRect(
      Rect.fromLTWH(size.width / 4, size.height - 3, size.width / 2, 2),
    );

    // Arrow head
    path.moveTo(size.width / 2, size.height / 4);
    path.lineTo(size.width / 3, size.height / 2.5);
    path.lineTo(size.width * 2 / 3, size.height / 2.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ImagePickerBottomSheet extends StatelessWidget {
  final Function(bool isPhotoLibrary) onImageSourceSelected;

  const ImagePickerBottomSheet({
    super.key,
    required this.onImageSourceSelected,
  });

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
              color: const Color(0xFF373C3A),
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          const SizedBox(height: 12),
          // Main content
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            color: const Color(0xFFDAE4E1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                MainHeading(
                  text: 'Select Image From',
                  iconPathOverride: 'assets/icons/upload-black.svg',
                ),

                const SizedBox(height: 24),

                // Image source options
                Column(
                  children: [
                    // Photo Library option
                    GestureDetector(
                      onTap: () => onImageSourceSelected(true),
                      child: Container(
                        height: 24,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Photo Library',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/photo.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF373C3A),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const DashedDivider(),
                    const SizedBox(height: 16),

                    // File option
                    GestureDetector(
                      onTap: () => onImageSourceSelected(false),
                      child: Container(
                        height: 24,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'File',
                              style: TextStyle(
                                fontFamily: 'Helvetica Now Display',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/folder.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF373C3A),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
              return const SizedBox(
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
