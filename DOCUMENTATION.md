# Invoice Generator App - Technical Documentation

This document provides comprehensive technical specifications for the Invoice Generator mobile application built with Flutter and Supabase.

## Navigation Structure

```
1. Splash Screen
2. Authentication Screen
3. Onboarding Flow (3 screens)
   ├── Company Basic Details Screen
   │   └── [Bottom Sheet] Select Currency
   ├── Company Address Screen
   │   └── [Bottom Sheet] Select Country
   └── Company Contact Screen
4. Home Screen - First Time Users
   ├── [Bottom Sheet] Theme Selector
   └── [Bottom Sheet] Settings
5. Home Screen - Active Users
   ├── [Bottom Sheet] Theme Selector
   └── [Bottom Sheet] Settings
6. Invoice Listing Screen
   ├── [Bottom Sheet] Invoice Sort
   └── [Bottom Sheet] Invoice Preview
   └── Invoice Create Screen
      ├── [Bottom Sheet] Select Client
      ├── [Bottom Sheet] Invoice Date Picker
      ├── [Bottom Sheet] Due Date Picker
      ├── [Bottom Sheet] Add Catalog Items
      ├── [Bottom Sheet] Add New Items
      ├── [Bottom Sheet] Edit Items
      └── [Bottom Sheet] Template Preview
      └── Created Invoice Preview
7. Client Screen
   ├── [Bottom Sheet] Client Sort
   └── Add Client Screen
      └── [Bottom Sheet] Select Country
8. Catalog Screen
   ├── [Bottom Sheet] Catalog Sort
   └── Add Catalog Items Screen
9. Settings (Bottom Sheet)
   ├── Business Details
   │   ├── [Bottom Sheet] Select Currency
   │   └── [Bottom Sheet] Select Country
   ├── Invoice Settings
   │   └── [Bottom Sheet] Invoice ID Format Configuration
   └── Client Settings
       └── [Bottom Sheet] Client ID Configuration
```

## Styling Guide

### Colors

**Primary Colors**

- Primary: `#F05022` (with theme color variations available)
- Primary Light: _To be defined_
- Primary Dark: _To be defined_

**Text Colors**

- Text Primary: `#373C3A`
- Text Secondary: `#8B9199`
- Text Disabled: `#B6BAC0`

**Background Colors**

- Background: `#DAE4E1` (used throughout the app)

**Status Colors**

- Status Paid: `#14D66D`
- Status Outstanding: `#D68814`
- Status Overdue: `#D61443`

**Icon Colors**

- Icon Primary: `#373C3A`
- Icon Accent: `#F05022`

**Divider Styles**

- Divider 1: 4px, Solid, `#CAD5D2`
- Divider 2: 1px, Solid, `#CAD5D2`
- Divider 3: 1px, Dashed, `#CAD5D2`

### Typography

**Font Family 1: 'Helvetica Now Display'**

- Heading 1: 60px, Bold, `#373C3A`
- Heading 2: 24px, Bold, `#373C3A`
- Heading 3: 16px, Bold, `#768581`
- Heading 4: 16px, Bold, `#3B3B3B` (for titles inside cards)
- Body (Input field - filled): 16px, Regular, `#373C3A`
- Body (Input field - placeholder): 16px, Regular, `#8D9694`

**Font Family 2: 'Victor Mono'**

- Caption: 12px, Bold, `#768581`
- Input field label: 14px, Bold, `#373C3A`
- First-time user heading: 16px, Bold, `#373C3A`

### Components

**Button Primary**

- Background: `#F05022`
- Text: 16px, Bold, `#FFFFFF`, Victor Mono, Bold
- Padding: Full-width horizontal, 12px vertical
- Height: 0px (auto)
- Border Radius: 0px

**Button Secondary**

- No background
- Icon + Text design
- Text: 14px, Bold, `#F05022`, Victor Mono, Bold
- Gap between icon and text: 4px

**Button Tertiary**

- No background
- Text only
- Text: 14px, Bold, `#F05022`, Victor Mono, Bold

**Input Field**

- Styling: Left-aligned labels, right-aligned placeholders, underlined design
- Height: 56px
- Border: Bottom only, 1px dashed `#CAD5D2`
- Border Radius: 0px
- Padding: 16px vertical (top and bottom)

**Text Area**

- Styling: Left-aligned labels, right-aligned placeholders, underlined design
- Height: Auto-adjusting based on content
- Padding: 16px vertical (top and bottom)

**List Items**

- Height: 56px
- Border Radius: 0px
- Padding: 16px vertical (top and bottom)

**Card**

- Background: `#DAE4E1`
- Border Radius: 0px
- Shadow: None
- Padding: 0px

### Layout & Spacing

**Spacing Scale**

- 4px, 8px, 16px, 24px, 32px, 48px

**Screen Padding**

- Horizontal: 20px (left and right)
- Top: 80px

### Animation & Interaction

- Smooth, fluid transitions inspired by iOS native apps
- Contextual animations based on user interactions
- Natural easing curves for all transitions

## Widget List

### Core UI Components

1. Button Primary
2. Button Secondary
3. Button Tertiary
4. Icon Button
5. Checkbox
6. Carousel Dots (for onboarding)
7. Text Input Field (3 states: placeholder, filled, error)
8. Text Area
9. Selection/Dropdown Input
10. Date Selection
11. Toggle Button
12. Information Box
13. Tabs (3 variations: 2-tab, 3-tab, 4-tab)

### Business Logic Components

14. Invoice Card (3 variations: paid, outstanding, overdue)
15. Template Listing
16. Add Catalog Items
17. Add New Items
18. Client Card
19. Catalog Card
20. List Items
21. Calendar

### Navigation and Structure Components

22. Section Heading
23. Bottom Navigation
24. Bottom Navigation Create Block
25. Bottom Navigation Close
26. Top Navigation

### Data Visualization Components

27. Revenue Chart
28. Top Clients Chart
29. Top Client Details

### Special Components

30. First Time Create Block

## Component Implementation Structure

### Base Components

These core components should be implemented first as they'll be used throughout the app:

```
lib/
├── widgets/
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   ├── tertiary_button.dart
│   │   └── icon_button.dart
│   ├── inputs/
│   │   ├── text_input.dart
│   │   ├── text_area.dart
│   │   ├── dropdown_input.dart
│   │   ├── date_input.dart
│   │   ├── checkbox.dart
│   │   └── toggle.dart
│   ├── navigation/
│   │   ├── bottom_nav.dart
│   │   ├── create_nav_block.dart
│   │   ├── nav_close.dart
│   │   └── top_nav.dart
│   ├── display/
│   │   ├── section_heading.dart
│   │   ├── information_box.dart
│   │   ├── carousel_dots.dart
│   │   └── tabs.dart
│   └── charts/
│       ├── revenue_chart.dart
│       └── client_chart.dart
```

### Business Components

These components build on the base components and implement specific business logic:

```
lib/
├── components/
│   ├── invoices/
│   │   ├── invoice_card.dart
│   │   ├── template_listing.dart
│   │   └── add_items.dart
│   ├── clients/
│   │   └── client_card.dart
│   ├── catalog/
│   │   └── catalog_card.dart
│   └── dashboard/
│       ├── revenue_overview.dart
│       └── client_overview.dart
```

### Bottom Sheets

The app makes extensive use of bottom sheets. These should be organized as:

```
lib/
├── bottom_sheets/
│   ├── settings/
│   │   ├── theme_selector.dart
│   │   ├── business_details.dart
│   │   ├── invoice_settings.dart
│   │   └── client_settings.dart
│   ├── invoices/
│   │   ├── invoice_sort.dart
│   │   ├── invoice_preview.dart
│   │   ├── select_client.dart
│   │   └── date_picker.dart
│   ├── clients/
│   │   └── client_sort.dart
│   └── catalog/
│       └── catalog_sort.dart
```

### Screens

Each main screen of the app:

```
lib/
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── auth/
│   │   └── auth_screen.dart
│   ├── onboarding/
│   │   ├── onboarding_screen.dart
│   │   ├── company_details_screen.dart
│   │   ├── company_address_screen.dart
│   │   └── company_contact_screen.dart
│   ├── home/
│   │   ├── first_time_home_screen.dart
│   │   └── home_screen.dart
│   ├── invoices/
│   │   ├── invoice_list_screen.dart
│   │   ├── create_invoice_screen.dart
│   │   └── invoice_preview_screen.dart
│   ├── clients/
│   │   ├── client_list_screen.dart
│   │   └── add_client_screen.dart
│   └── catalog/
│       ├── catalog_list_screen.dart
│       └── add_catalog_screen.dart
```

## Theming Implementation

Since the app supports multiple theme colors and a dark theme, implement a robust theme system:

```dart
// Example structure for themes
class AppTheme {
  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      primaryColor: primaryColor,
      backgroundColor: Color(0xFFDAE4E1),
      textTheme: TextTheme(
        headline1: TextStyle(
          fontFamily: 'Helvetica Now Display',
          fontSize: 60,
          fontWeight: FontWeight.bold,
          color: Color(0xFF373C3A),
        ),
        // Define other text styles...
      ),
      // Define other theme properties...
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    // Define dark theme...
  }
}
```

## Data Models

```dart
// User Model
class User {
  final String id;
  final String email;
  String companyName;
  String currency;
  double? taxRate;
  Address address;
  ContactInfo contactInfo;
  final DateTime createdAt;
  DateTime updatedAt;
}

// Organization Model
class Organization {
  final String id;
  final String userId;
  String name;
  String currency;
  double? taxRate;
  Address address;
  ContactInfo contactInfo;
  final DateTime createdAt;
  DateTime updatedAt;
}

// Client Model
class Client {
  final String id;
  final String userId;
  final String organizationId;
  bool isOrganization;
  String name;
  String? taxId;
  Address address;
  ContactInfo contactInfo;
  String? notes;
  final DateTime createdAt;
  DateTime updatedAt;
}

// Invoice Model
class Invoice {
  final String id;
  final String userId;
  final String organizationId;
  final String clientId;
  String invoiceNumber;
  DateTime issueDate;
  DateTime dueDate;
  List<InvoiceItem> items;
  double subtotal;
  double taxRate;
  double taxAmount;
  double? discountAmount;
  double total;
  String? notes;
  String templateId;
  InvoiceStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
}

// InvoiceItem Model
class InvoiceItem {
  final String id;
  final String invoiceId;
  String? catalogItemId;
  String description;
  double quantity;
  double unitPrice;
  double amount;
  final DateTime createdAt;
  DateTime updatedAt;
}

// CatalogItem Model
class CatalogItem {
  final String id;
  final String userId;
  final String organizationId;
  String name;
  String? description;
  double defaultQuantity;
  double price;
  final DateTime createdAt;
  DateTime updatedAt;
}

// Address Model
class Address {
  String street;
  String city;
  String? state;
  String zipCode;
  String country;
}

// ContactInfo Model
class ContactInfo {
  String email;
  String? phone;
  String? website;
}

// InvoiceStatus Enum
enum InvoiceStatus {
  paid,
  outstanding,
  overdue
}
```

## Next Steps for Development

1. **Project Setup**

   - Initialize Flutter project
   - Set up Supabase integration
   - Configure fonts and assets

2. **Core Implementation**

   - Create theme system with color variables
   - Implement base UI components
   - Set up navigation structure

3. **Authentication and Onboarding**

   - Implement authentication flow
   - Create onboarding screens
   - Set up user data storage

4. **Core Functionality**

   - Implement invoice creation and management
   - Build client management features
   - Create catalog functionality

5. **Dashboard and Reporting**

   - Implement home screen with charts and metrics
   - Create financial reporting features

6. **Export and Sharing**

   - Add PDF generation for invoices
   - Implement sharing functionality

7. **Settings and Customization**

   - Build theme selection
   - Implement business settings
   - Create invoice/client settings

8. **Testing and Refinement**

   - User testing
   - Performance optimization
   - UI/UX refinement

9. **Deployment**
   - Prepare for app store submission
   - Create marketing materials
   - Launch strategy
