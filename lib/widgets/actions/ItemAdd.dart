import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemAdd extends StatefulWidget {
  final String title;
  final String amount;
  final String currency;
  final VoidCallback? onSelect;
  final Function(int)? onQuantityChanged;
  final bool isSelected;
  final int initialQuantity;
  final bool isAlreadyAdded;

  const ItemAdd({
    Key? key,
    this.title = 'Website Design',
    this.amount = '4500.00',
    this.currency = 'USD',
    this.onSelect,
    this.onQuantityChanged,
    this.isSelected = false,
    this.initialQuantity = 0,
    this.isAlreadyAdded = false,
  }) : super(key: key);

  @override
  State<ItemAdd> createState() => _ItemAddState();
}

class _ItemAddState extends State<ItemAdd> {
  late bool _isSelected;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
    _quantity = widget.initialQuantity;
  }

  @override
  void didUpdateWidget(ItemAdd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      setState(() {
        _isSelected = widget.isSelected;
        if (!_isSelected) {
          _quantity = 0;
        } else if (_quantity == 0) {
          _quantity = 1;
        }
      });
    }

    if (oldWidget.initialQuantity != widget.initialQuantity) {
      setState(() {
        _quantity = widget.initialQuantity;
        _isSelected = _quantity > 0;
      });
    }
  }

  void _toggleSelection() {
    if (widget.isAlreadyAdded) return;

    setState(() {
      _isSelected = !_isSelected;
      if (_isSelected && _quantity == 0) {
        _quantity = 1;
      } else if (!_isSelected) {
        _quantity = 0;
      }
    });

    if (widget.onSelect != null) {
      widget.onSelect!();
    }

    if (widget.onQuantityChanged != null) {
      widget.onQuantityChanged!(_quantity);
    }
  }

  void _decreaseQuantity() {
    if (widget.isAlreadyAdded) return;

    if (_quantity > 0) {
      setState(() {
        _quantity--;
        _isSelected = _quantity > 0;
      });

      if (widget.onQuantityChanged != null) {
        widget.onQuantityChanged!(_quantity);
      }

      if (!_isSelected && widget.onSelect != null) {
        widget.onSelect!();
      }
    }
  }

  void _increaseQuantity() {
    if (widget.isAlreadyAdded) return;

    setState(() {
      _quantity++;
      if (!_isSelected && _quantity > 0) {
        _isSelected = true;
        if (widget.onSelect != null) {
          widget.onSelect!();
        }
      }
    });

    if (widget.onQuantityChanged != null) {
      widget.onQuantityChanged!(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isAlreadyAdded ? 0.5 : 1.0,
      child: Container(
        width: 362,
        color: Colors.transparent,
        child: Row(
          children: [
            // Left side with selection (expanded to full height)
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _toggleSelection,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with checkbox and title
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: SvgPicture.asset(
                            _isSelected
                                ? 'assets/icons/checked.svg'
                                : 'assets/icons/unchecked.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: Color(0xFF3A3A3A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Helvetica Now Display',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // QTY label
                    Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Text(
                        'QTY',
                        style: TextStyle(
                          color: Color(0xFF8D9694),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Victor Mono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right side with price and quantity controls
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.currency,
                        style: TextStyle(
                          color: Color(0xFF8D9694),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Victor Mono',
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        widget.amount,
                        style: TextStyle(
                          color: Color(0xFF3A3A3A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Helvetica Now Display',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _decreaseQuantity,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: SvgPicture.asset(
                            'assets/icons/minus-qty.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              widget.isAlreadyAdded
                                  ? Colors.grey
                                  : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 20,
                        alignment: Alignment.center,
                        child: Text(
                          _quantity.toString(),
                          style: TextStyle(
                            color: Color(0xFF3A3A3A),
                            fontSize: 16,
                            fontFamily: 'Helvetica Now Display',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: _increaseQuantity,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: SvgPicture.asset(
                            'assets/icons/plus-qty.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              widget.isAlreadyAdded
                                  ? Colors.grey
                                  : Colors.black,
                              BlendMode.srcIn,
                            ),
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
      ),
    );
  }
}
