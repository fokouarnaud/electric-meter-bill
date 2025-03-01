# Electric Meter Billing

A Flutter application for managing electric meter readings and billing.

## Features

### Meter Management
- Add, edit, and delete meters
- Track meter details (location, client name, price per kWh)
- View meter statistics and history

### Meter Readings
- Capture meter readings using the device camera
- OCR for automatic reading value extraction
- Reading verification and manual correction
- Consumption calculation and tracking
- Image storage for future reference

### Billing
- Automatic bill generation from meter readings
- PDF bill generation with customizable templates
- Email functionality for sending bills
- Payment status tracking
- Payment reminders via notifications
- Support for bulk bill operations

### Reports
- Monthly consumption reports
- Bill history and statistics
- Export reports as PDF

### Data Management
- Local SQLite database
- Backup and restore functionality
- Image backup
- Data export options

### User Interface
- Material Design 3
- Light and dark theme support
- System theme integration
- Responsive layout
- Intuitive navigation

## Technical Details

### Architecture
- Clean Architecture
- BLoC pattern for state management
- Repository pattern for data access
- Dependency injection

### Technologies
- Flutter & Dart
- SQLite for local storage
- Camera integration
- Google ML Kit for OCR
- PDF generation
- Email integration
- Local notifications
- File system operations

### Dependencies
- flutter_bloc: State management
- sqflite: Local database
- image_picker & camera: Image capture
- google_mlkit_text_recognition: OCR
- pdf & printing: PDF generation
- flutter_email_sender: Email functionality
- archive: Backup/restore
- shared_preferences: Theme persistence
- flutter_local_notifications: Notifications
- get_it: Dependency injection

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Ensure you have the required permissions:
   - Camera
   - Storage
   - Notifications
4. Run the app using `flutter run`

## Project Structure

```
lib/
├── data/
│   ├── datasources/
│   │   └── database_helper.dart
│   ├── models/
│   │   ├── bill_model.dart
│   │   ├── meter_model.dart
│   │   └── meter_reading_model.dart
│   └── repositories/
│       ├── bill_repository_impl.dart
│       ├── meter_reading_repository_impl.dart
│       └── meter_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── bill.dart
│   │   ├── meter.dart
│   │   └── meter_reading.dart
│   └── repositories/
│       ├── bill_repository.dart
│       ├── meter_reading_repository.dart
│       └── meter_repository.dart
├── presentation/
│   ├── bloc/
│   │   ├── bill/
│   │   ├── meter/
│   │   ├── meter_reading/
│   │   └── theme/
│   ├── screens/
│   │   ├── add_meter_reading_screen.dart
│   │   ├── bills_screen.dart
│   │   ├── camera_screen.dart
│   │   ├── home_screen.dart
│   │   ├── meter_reading_image_screen.dart
│   │   ├── meter_readings_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       └── email_dialog.dart
├── services/
│   ├── backup_service.dart
│   ├── email_service.dart
│   ├── notification_service.dart
│   ├── pdf_service.dart
│   ├── pdf_widgets.dart
│   └── theme_service.dart
├── injection.dart
└── main.dart
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
#   e l e c t r i c - m e t e r - b i l l  
 