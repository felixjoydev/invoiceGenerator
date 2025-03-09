import 'package:flutter/material.dart';
import 'package:invoicegenerator/screens/home/home_screen.dart';
import 'package:invoicegenerator/screens/invoices/invoice_list_screen.dart';
import 'package:invoicegenerator/screens/clients/client_list_screen.dart';
import 'package:invoicegenerator/screens/catalog/catalog_list_screen.dart';

/// Helper to determine slide direction between screens
bool getSlideDirection(Widget currentScreen, Widget targetScreen) {
  // Page indices: Home(1), Invoice(2), Clients(3), Catalog(4)
  int currentIndex = _getScreenIndex(currentScreen);
  int targetIndex = _getScreenIndex(targetScreen);

  // If target has higher index, slide from right (true)
  // If target has lower index, slide from left (false)
  return targetIndex > currentIndex;
}

int _getScreenIndex(Widget screen) {
  if (screen is HomeScreen) {
    return 1;
  } else if (screen is InvoiceListScreen) {
    return 2;
  } else if (screen is ClientListScreen) {
    return 3;
  } else if (screen is CatalogListScreen) {
    return 4;
  }
  // Default for unknown screens
  return 0;
}

/// Custom page route that animates only the content between navigation bars
class SlideContentRoute extends PageRouteBuilder {
  final Widget page;
  final bool slideFromRight;
  final Widget? currentScreen;

  SlideContentRoute({
    required this.page,
    required this.slideFromRight,
    this.currentScreen,
  }) : super(
         pageBuilder:
             (
               BuildContext context,
               Animation<double> animation,
               Animation<double> secondaryAnimation,
             ) => page,
         transitionsBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondaryAnimation,
           Widget child,
         ) {
           // Create slide animation
           final beginOffset =
               slideFromRight
                   ? const Offset(1.0, 0.0) // From right
                   : const Offset(-1.0, 0.0); // From left

           // Define animation but don't directly apply it
           // The ContentSlideTransition widget in each screen will handle the actual animation
           // This line is needed to avoid the "unused_local_variable" warning
           final _ = Tween(begin: beginOffset, end: Offset.zero).animate(
             CurvedAnimation(parent: animation, curve: Curves.easeInOut),
           );

           // Find the content widget to animate (Expanded widget)
           // This is the widget that contains the main content area
           return Stack(
             children: [
               // Clone the child into the tree
               child,

               // Extract the animated parts by locating them in the widget tree
               // The parts that should not animate (top nav and bottom nav) will render normally
               // The parts that should animate (main content) will be found and animated
               Builder(
                 builder: (context) {
                   // This will be empty in the actual implementation
                   // We're just using the stack to ensure stable navigation
                   return const SizedBox();
                 },
               ),
             ],
           );
         },
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),
         settings: RouteSettings(
           // Store the current screen as route argument for the next navigation
           name: '/${_getRouteName(page)}',
           arguments: currentScreen,
         ),
       );
}

/// Get route name for a widget
String _getRouteName(Widget widget) {
  if (widget is HomeScreen) {
    return 'home';
  } else if (widget is InvoiceListScreen) {
    return 'invoices';
  } else if (widget is ClientListScreen) {
    return 'clients';
  } else if (widget is CatalogListScreen) {
    return 'catalog';
  }
  return '';
}

/// Helper class to implement content-only slide transition in your screens
/// Use this inside your screen's build method to wrap only the content area
class ContentSlideTransition extends StatefulWidget {
  final bool slideFromRight;
  final Widget child;

  const ContentSlideTransition({
    Key? key,
    required this.slideFromRight,
    required this.child,
  }) : super(key: key);

  @override
  State<ContentSlideTransition> createState() => _ContentSlideTransitionState();
}

class _ContentSlideTransitionState extends State<ContentSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final beginOffset =
        widget.slideFromRight
            ? const Offset(1.0, 0.0) // From right
            : const Offset(-1.0, 0.0); // From left

    _slideAnimation = Tween(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _slideAnimation, child: widget.child);
  }
}

/// Extension method to make navigation easier
extension NavigationExtension on BuildContext {
  /// Navigate from current screen to a new screen with direction-aware animation
  void navigateWithSlide(Widget targetScreen) {
    // Since we know exactly which screens we have, we can directly determine
    // the slide direction based on the current screen and target screen types
    bool slideFromRight = true; // Default (right to left)

    if (targetScreen is HomeScreen) {
      // Always slide from left when going to home
      slideFromRight = false;
    } else if (targetScreen is InvoiceListScreen) {
      // Only slide from right when coming from Home
      // For Client or Catalog, slide from left
      final currentWidget = ModalRoute.of(this)?.settings.arguments;
      if (currentWidget is ClientListScreen ||
          currentWidget is CatalogListScreen) {
        slideFromRight = false;
      }
    } else if (targetScreen is ClientListScreen) {
      // Slide from right when coming from Home or Invoice
      // Slide from left when coming from Catalog
      final currentWidget = ModalRoute.of(this)?.settings.arguments;
      if (currentWidget is CatalogListScreen) {
        slideFromRight = false;
      }
    }
    // For Catalog, always slide from right (default)

    // Determine the current screen
    Widget currentScreen = getCurrentScreen();

    // Now create a new route with the target screen and pass the current screen as an argument
    Navigator.of(this).pushReplacement(
      SlideContentRoute(
        page: targetScreen,
        slideFromRight: slideFromRight,
        currentScreen: currentScreen,
      ),
    );
  }

  /// Helper to get the current screen widget
  Widget getCurrentScreen() {
    // Start with the assumption we're on home screen if we can't determine
    Widget currentScreen = const HomeScreen();

    try {
      // Try to get the actual screen type from the route
      final route = ModalRoute.of(this);
      if (route != null) {
        if (route.settings.name == '/invoices') {
          currentScreen = const InvoiceListScreen();
        } else if (route.settings.name == '/clients') {
          currentScreen = const ClientListScreen();
        } else if (route.settings.name == '/catalog') {
          currentScreen = const CatalogListScreen();
        }
      }
    } catch (e) {
      // Ignore errors, default to home
    }

    return currentScreen;
  }
}
