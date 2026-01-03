# Audit2Fund

Audit2Fund is a comprehensive loan management and auditing application designed to streamline the tracking of loan files, funds, and audit events. Built with Flutter, it offers a robust cross-platform experience (macOS and Windows) for financial professionals to manage their portfolios efficiently using a local database.

## Features

- **Dashboard Overview**: Get a bird's-eye view of your loan portfolio with key statistics, status breakdowns, and activity feeds.
- **Loan Management**: Create, view, and update loan files with detailed information including client names, amounts, and rich-text notes.
- **Status Tracking**: Track the lifecycle of loans through customizable statuses to ensure visibility at every stage.
- **Audit Trail**: Automatically record audit events for significant actions (e.g., status changes, updates) to ensure accountability and traceability.
- **Follow-up System**: Set intelligent reminders and notifications for important follow-ups, ensuring timely client communication.
- **Reporting**: Generate insightful reports to analyze performance and loan trends.
- **Secure Local Storage**: Data is stored securely on the local device using SQLite.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Flutter Riverpod
- **Database**: SQLite (via `sqflite_common_ffi` and `sqlite3_flutter_libs`)
- **Notifications**: Flutter Local Notifications
- **UI/Theming**: Custom Material Design theme with responsive layouts
- **Desktop Integration**: Window Manager for native desktop window control

## Installation & Deployment

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (Version 3.10.4 or higher recommended).
- **macOS**: 
  - macOS Operating System.
  - [Xcode](https://developer.apple.com/xcode/) installed.
  - [CocoaPods](https://cocoapods.org/) installed (`sudo gem install cocoapods`).
- **Windows**: 
  - Windows 10 or 11.
  - [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++" workload installed.

### Mac Deployment (macOS)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/harikumar14081996/audit2fund.git
   cd audit2fund
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install CocoaPods dependencies:**
   ```bash
   cd macos
   pod install
   cd ..
   ```

4. **Run in Debug Mode:**
   To run the app locally during development:
   ```bash
   flutter run -d macos
   ```

5. **Build for Release:**
   To create a production-ready application bundle (`.app`):
   ```bash
   flutter build macos
   ```
   The built application can be found in `build/macos/Build/Products/Release/audit2fund.app`.

### Windows Deployment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/harikumar14081996/audit2fund.git
   cd audit2fund
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run in Debug Mode:**
   To run the app locally during development:
   ```bash
   flutter run -d windows
   ```

4. **Build for Release:**
   To create a standalone executable (`.exe`):
   ```bash
   flutter build windows
   ```
   The built application and necessary DLLs can be found in `build/windows/runner/Release/`. You can zip this folder to distribute the application.

## Project Structure

- `lib/domain`: Contains core business rules, entities (`LoanFile`, `AuditEvent`), and abstract repository interfaces.
- `lib/data`: Handles data persistence, repository implementations, and database services (`DatabaseService`).
- `lib/presentation`: Contains all UI code, screens (`DashboardScreen`, `LoanDetailScreen`), and Riverpod providers.
- `lib/core`: Holds shared constants, themes (`AppTheme`), and utility classes.

## Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add some amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

## License

This project is licensed under the MIT License.
