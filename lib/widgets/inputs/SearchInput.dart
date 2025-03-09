import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/inputs/utils/dashed_line_painter.dart';

class SearchInput extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final String hintText;

  const SearchInput({
    Key? key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.hintText = 'Search',
  }) : super(key: key);

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _clearSearch() {
    _controller.clear();
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/search.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                const Color.fromRGBO(118, 133, 129, 1),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8), // 8px spacing
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF373C3A),
                  fontFamily: 'Helvetica Now Display',
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(118, 133, 129, 1),
                    fontFamily: 'Helvetica Now Display',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            // Clear button - only visible when there's text
            if (_hasText)
              GestureDetector(
                onTap: _clearSearch,
                child: SvgPicture.asset(
                  'assets/icons/close-box.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF8D9694),
                    BlendMode.srcIn,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
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

// A more functional version of the search input that can be used in forms
class FunctionalSearchInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const FunctionalSearchInput({
    Key? key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<FunctionalSearchInput> createState() => _FunctionalSearchInputState();
}

class _FunctionalSearchInputState extends State<FunctionalSearchInput> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _clearSearch() {
    widget.controller.clear();
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/search.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                const Color.fromRGBO(118, 133, 129, 1),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8), // 8px spacing
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromRGBO(118, 133, 129, 1),
                  fontFamily: 'Helvetica Now Display',
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(118, 133, 129, 1),
                    fontFamily: 'Helvetica Now Display',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            // Clear button - only visible when there's text
            if (_hasText)
              GestureDetector(
                onTap: _clearSearch,
                child: SvgPicture.asset(
                  'assets/icons/close-box.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF8D9694),
                    BlendMode.srcIn,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
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

// Example usage in a screen (keeping this for reference)
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FunctionalSearchInput(
              controller: _searchController,
              hintText: 'Search',
              onChanged: (value) {
                // Handle search as user types
                print('Search query: $value');
              },
              onSubmitted: (value) {
                // Handle search when user presses enter/search button
                print('Search submitted: $value');
              },
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  'Search results will appear here',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
