import 'package:flutter/material.dart';
import 'package:invoicegenerator/theme/app_theme.dart';
import 'package:invoicegenerator/services/client_service.dart';
import 'package:invoicegenerator/models/client.dart';
import 'package:invoicegenerator/screens/clients/client_list_screen.dart';
import 'package:invoicegenerator/utils/route_transitions.dart';
import 'package:invoicegenerator/widgets/charts/client_chart.dart';
import 'package:invoicegenerator/utils/client_adapter.dart';

class TopClients extends StatefulWidget {
  const TopClients({super.key});

  @override
  State<TopClients> createState() => _TopClientsState();
}

class _TopClientsState extends State<TopClients> {
  // Client service instance
  final ClientService _clientService = ClientService();

  // List to store top clients
  List<Client> _topClients = [];

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize with empty state to prevent delay
    _updateTopClients();

    // Load clients in background and listen for changes
    _loadClientsAsync();
    _clientService.addListener(_onClientDataChanged);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    _clientService.removeListener(_onClientDataChanged);
    super.dispose();
  }

  // Load clients from the service (async but don't block UI)
  void _loadClientsAsync() async {
    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      await _clientService.init();
      // Force a sync with Hive to get the latest clients
      await _clientService.syncWithHive();

      if (mounted) {
        _updateTopClients();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update when client data changes
  void _onClientDataChanged() {
    if (mounted) {
      _updateTopClients();
    }
  }

  // Update the list of top clients
  void _updateTopClients() {
    // Get all clients from the service
    List<Client> allClients = List.from(_clientService.clients);

    // Sort by amount (highest to lowest)
    allClients.sort((a, b) => b.amount.compareTo(a.amount));

    // Take only the top 4 (or less if there are fewer clients)
    setState(() {
      _topClients = allClients.take(4).toList();
    });
  }

  // Navigate to client list screen
  void _viewAllClients() {
    context.navigateWithSlide(const ClientListScreen());
  }

  @override
  Widget build(BuildContext context) {
    // Find the highest amount for progress bar calculation
    double maxAmount =
        _topClients.isNotEmpty
            ? _topClients.first.amount
            : 1.0; // Prevent division by zero

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Top Clients',
                style: TextStyle(
                  color: Color(0xFF36393A),
                  fontSize: 24,
                  fontFamily: 'Helvetica Now Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    _isLoading
                        ? [
                          // Show loading indicator when loading
                          SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF05022),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ]
                        : _topClients.isNotEmpty
                        ? _buildClientList(maxAmount)
                        : [
                          // Show placeholder message if no clients
                          Text(
                            'No clients yet. Add your first client!',
                            style: TextStyle(
                              color: Color(0xFF8D9694),
                              fontSize: 16,
                              fontFamily: 'Helvetica Now Display',
                            ),
                          ),
                        ],
              ),
            ],
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _viewAllClients,
            child: Center(
              child: Text(
                AppTheme.ensureVictorMonoUppercase('View all clients'),
                style: TextStyle(
                  color: Color(0xFFF05022),
                  fontSize: 14,
                  fontFamily: 'Victor Mono',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(height: 4, color: Color(0xFFCAD5D2)),
        ],
      ),
    );
  }

  // Build the list of client items
  List<Widget> _buildClientList(double maxAmount) {
    List<Widget> clientWidgets = [];

    for (int i = 0; i < _topClients.length; i++) {
      final client = _topClients[i];

      // Add client item
      clientWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  client.name,
                  style: TextStyle(
                    color: Color(0xFF3A3A3A),
                    fontSize: 16,
                    fontFamily: 'Helvetica Now Display',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      client.currency ?? 'USD',
                      style: TextStyle(
                        color: Color(0xFF8D9694),
                        fontSize: 14,
                        fontFamily: 'Victor Mono',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(width: 7),
                    Text(
                      client.amount.toStringAsFixed(2),
                      style: TextStyle(
                        color: Color(0xFF3A3A3A),
                        fontSize: 16,
                        fontFamily: 'Helvetica Now Display',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            ClientChart(amount: client.amount, maxAmount: maxAmount),
          ],
        ),
      );

      // Add spacing between client items, except for the last one
      if (i < _topClients.length - 1) {
        clientWidgets.add(SizedBox(height: 8));
      }
    }

    return clientWidgets;
  }
}
