# Invoice Generator

A Flutter application for generating and managing invoices with Supabase backend.

## Features

- **Authentication**: Secure user authentication and authorization system
- **Invoice Management**: Create, edit, and manage invoices
- **Client Management**: Add and manage client information
- **Catalog Items**: Create reusable items for quick invoice creation
- **PDF Generation**: Export invoices as PDF files
- **Dashboard**: Visualize financial data and track payments
- **Multiple Themes**: Customize the app appearance

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
- **State Management**: Flutter Riverpod
- **PDF Generation**: pdf, printing packages
- **Animations**: Lottie, flutter_staggered_animations
- **Charts**: fl_chart

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / VS Code
- Supabase account

### Installation

1. Clone the repository

```bash
git clone https://github.com/felixjoydev/invoiceGenerator.git
```

2. Navigate to the project directory

```bash
cd invoicegenerator
```

3. Install dependencies

```bash
flutter pub get
```

4. Update Supabase credentials

   - Open `lib/main.dart`
   - Replace `SUPABASE_URL` and `SUPABASE_ANON_KEY` with your actual Supabase credentials

5. Run the app

```bash
flutter run
```

## Project Structure

The project follows a modular architecture with the following structure:

```
lib/
├── widgets/         # Reusable UI components
├── components/      # Business logic components
├── bottom_sheets/   # Bottom sheet UIs
├── screens/         # App screens
├── models/          # Data models
├── services/        # API services and providers
├── utils/           # Utility functions
└── theme/           # App theming
```

## Design

The app follows a clean, minimal design with:

- Primary color: `#F05022`
- Background color: `#DAE4E1`
- Font families: 'Helvetica Now Display' and 'Victor Mono'

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Felix Joy - [felixjoydc@gmail.com](mailto:felixjoydc@gmail.com)

Project Link: [https://github.com/felixjoydev/invoiceGenerator](https://github.com/felixjoydev/invoiceGenerator)
