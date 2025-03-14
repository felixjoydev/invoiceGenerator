import 'package:flutter/material.dart';
import 'package:invoicegenerator/widgets/buttons/primary_button.dart';
import 'package:invoicegenerator/widgets/buttons/secondary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:invoicegenerator/widgets/inputs/SearchInput.dart';
import 'package:invoicegenerator/widgets/actions/ClientAdd.dart';
import 'package:invoicegenerator/services/client_service.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/widgets/display/app_icon.dart';

class SelectClientSheet extends StatefulWidget {
  final VoidCallback? onAddNewClientPressed;
  final Function(Client)? onClientSelected;
  final String? preSelectedClientId;

  const SelectClientSheet({
    super.key,
    this.onAddNewClientPressed,
    this.onClientSelected,
    this.preSelectedClientId,
  });

  @override
  State<SelectClientSheet> createState() => _SelectClientSheetState();
}

class _SelectClientSheetState extends State<SelectClientSheet> {
  final TextEditingController _searchController = TextEditingController();
  final _clientService = ClientService();
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;

  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  Client? _selectedClient;
  Map<String, bool> _selectionState = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize with pre-selected client
    if (widget.preSelectedClientId != null) {
      // We'll set this after loading clients
    }

    _loadClients();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset <= 0) {
      setState(() {
        _isAtTop = true;
      });
    } else if (_isAtTop) {
      setState(() {
        _isAtTop = false;
      });
    }
  }

  // Load clients from the service
  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize the service
      await _clientService.init();

      // Get all clients
      final clients = _clientService.clients;

      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;

        // Initialize selection state
        for (var client in clients) {
          bool isPreSelected = widget.preSelectedClientId == client.clientId;
          _selectionState[client.clientId] = isPreSelected;

          // Set selected client if it's the pre-selected one
          if (isPreSelected) {
            _selectedClient = client;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleAddNewClient() {
    // Close the current bottom sheet
    Navigator.pop(context);

    // Call the passed callback if it exists
    if (widget.onAddNewClientPressed != null) {
      widget.onAddNewClientPressed!();
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClients = List.from(_clients);
      } else {
        _filteredClients =
            _clients.where((client) {
              return client.name.toLowerCase().contains(query.toLowerCase()) ||
                  client.clientId.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }

      // If no results are found and we're not at the top,
      // don't change the scroll position
      if (_filteredClients.isEmpty && !_isAtTop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Keep scroll position to prevent jarring UI shift
          // This only applies when search finds no results
        });
      }
    });
  }

  void _toggleClientSelection(Client client) {
    // If we already have a selected client that's different, deselect it
    if (_selectedClient != null &&
        _selectedClient!.clientId != client.clientId) {
      _selectionState[_selectedClient!.clientId] = false;
    }

    setState(() {
      // Update selection state
      bool newState = !(_selectionState[client.clientId] ?? false);
      _selectionState[client.clientId] = newState;

      // Update selected client
      _selectedClient = newState ? client : null;
    });
  }

  // Close the sheet and pass selected client back to parent
  void _applySelection() {
    if (widget.onClientSelected != null && _selectedClient != null) {
      widget.onClientSelected!(_selectedClient!);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum height (screen height - 80px)
    final double maxHeight = MediaQuery.of(context).size.height - 120;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (_isAtTop && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        height: maxHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
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
            // Main content
            Expanded(
              child: Container(
                width: double.infinity,
                color: Color(0xFFDAE4E1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Add New Client button
                          MainHeadingWithButton(
                            text: 'Select Client',
                            iconPath: 'assets/icons/clients.svg',
                            onAddNewItemPressed: _handleAddNewClient,
                          ),

                          // Add spacing between heading and search input
                          SizedBox(height: 8),

                          // Search input
                          SearchInput(
                            controller: _searchController,
                            hintText: 'Search clients',
                            onChanged: _handleSearch,
                          ),

                          // Add spacing between search input and client list
                          SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Scrollable Clients List
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification) {
                              if (notification.metrics.pixels <= 0) {
                                setState(() {
                                  _isAtTop = true;
                                });
                              } else if (_isAtTop) {
                                setState(() {
                                  _isAtTop = false;
                                });
                              }
                            }
                            return false;
                          },
                          child:
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _filteredClients.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No clients found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF8D9694),
                                        fontFamily: 'Helvetica Now Display',
                                      ),
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: _buildClientsList(),
                                  ),
                        ),
                      ),
                    ),

                    // Fixed Bottom Button Section
                    if (_selectedClient != null)
                      Container(
                        width: double.infinity,
                        color: Color(0xFFDAE4E1),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        child: PrimaryButton(
                          label: 'SELECT CLIENT',
                          onPressed: _applySelection,
                          isEnabled: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the list of clients
  Widget _buildClientsList() {
    return Column(
      children: List.generate(_filteredClients.length * 2 - 1, (index) {
        // For even indices, show the client
        if (index.isEven) {
          final clientIndex = index ~/ 2;
          final client = _filteredClients[clientIndex];
          final isSelected = _selectionState[client.clientId] ?? false;

          return GestureDetector(
            key: ValueKey(client.clientId),
            onTap: () => _toggleClientSelection(client),
            behavior: HitTestBehavior.opaque,
            child: SelectableClientAdd(
              clientName: client.name,
              clientId: client.clientId,
              isSelected: isSelected,
            ),
          );
        }
        // For odd indices, show a divider
        else {
          return Column(
            children: const [
              SizedBox(height: 16),
              DashedDivider(),
              SizedBox(height: 16),
            ],
          );
        }
      }),
    );
  }
}

/// Selectable client add widget for the bottom sheet
class SelectableClientAdd extends StatelessWidget {
  final String clientName;
  final String clientId;
  final bool isSelected;

  const SelectableClientAdd({
    Key? key,
    required this.clientName,
    required this.clientId,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              isSelected ? SelectedCheckbox() : UnselectedCheckbox(),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  clientName,
                  style: TextStyle(
                    color: Color(0xFF3A3A3A),
                    fontSize: 16,
                    fontFamily: 'Helvetica Now Display',
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: 32),
            child: Row(
              children: [
                Text(
                  clientId,
                  style: TextStyle(
                    color: Color(0xFF76857F),
                    fontSize: 12,
                    fontFamily: 'Victor Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selected checkbox (orange with light gray checkmark)
class SelectedCheckbox extends StatelessWidget {
  const SelectedCheckbox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color orangeColor = Color(0xFFF05022);
    final Color lightGrayColor = Color(0xFFDAE4E1);

    return Container(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // Main rectangle
          Positioned(
            left: 5,
            top: 3,
            child: Container(width: 14, height: 16, color: orangeColor),
          ),
          // Bottom rectangle
          Positioned(
            left: 5,
            top: 19,
            child: Container(width: 14, height: 2, color: orangeColor),
          ),
          // Left rectangle
          Positioned(
            left: 3,
            top: 3,
            child: Container(width: 2, height: 18, color: orangeColor),
          ),
          // Right rectangle
          Positioned(
            left: 19,
            top: 3,
            child: Container(width: 2, height: 18, color: orangeColor),
          ),
          // Checkmark dots
          Positioned(
            left: 7,
            top: 12,
            child: Container(width: 2, height: 2, color: lightGrayColor),
          ),
          Positioned(
            left: 9,
            top: 14,
            child: Container(width: 2, height: 2, color: lightGrayColor),
          ),
          Positioned(
            left: 11,
            top: 12,
            child: Container(width: 2, height: 2, color: lightGrayColor),
          ),
          Positioned(
            left: 13,
            top: 10,
            child: Container(width: 2, height: 2, color: lightGrayColor),
          ),
          Positioned(
            left: 15,
            top: 8,
            child: Container(width: 2, height: 2, color: lightGrayColor),
          ),
        ],
      ),
    );
  }
}

/// Unselected checkbox (just the outline)
class UnselectedCheckbox extends StatelessWidget {
  const UnselectedCheckbox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color outlineColor = Color(0xFFCAD5D2);

    return Container(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // Left rectangle
          Positioned(
            left: 3,
            top: 3,
            child: Container(width: 2, height: 18, color: outlineColor),
          ),
          // Top rectangle
          Positioned(
            left: 5,
            top: 3,
            child: Container(width: 14, height: 2, color: outlineColor),
          ),
          // Right rectangle
          Positioned(
            left: 19,
            top: 3,
            child: Container(width: 2, height: 18, color: outlineColor),
          ),
          // Bottom rectangle
          Positioned(
            left: 5,
            top: 19,
            child: Container(width: 14, height: 2, color: outlineColor),
          ),
        ],
      ),
    );
  }
}

/// DashedDivider copied from invoice_item.dart
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
              return SizedBox(
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

/// MainHeading with a SecondaryButton on the right
class MainHeadingWithButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback? onAddNewItemPressed;

  const MainHeadingWithButton({
    super.key,
    required this.text,
    required this.iconPath,
    this.onAddNewItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title with icon on left
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF373C3A),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF373C3A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Helvetica Now Display',
                  ),
                ),
              ],
            ),

            // Add New Client button on right
            SecondaryButton(
              iconType: IconType.addItem,
              text: 'ADD NEW CLIENT',
              onPressed: onAddNewItemPressed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 4,
          width: double.infinity,
          color: const Color(0xFFCAD5D2),
        ),
      ],
    );
  }
}
