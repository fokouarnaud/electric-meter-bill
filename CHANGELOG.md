# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-13

### Added
- Initial release
- Meter management system
  - Add, edit, and delete meters
  - Track meter details and history
- Meter readings functionality
  - Camera integration for capturing readings
  - OCR for automatic value extraction
  - Reading verification
  - Image storage
- Billing system
  - Automatic bill generation
  - PDF generation with customizable templates
  - Email functionality
  - Payment tracking
  - Payment reminders via notifications
- Data management
  - Local SQLite database
  - Backup and restore functionality
  - Data export options
- User interface
  - Material Design 3
  - Light and dark theme support
  - System theme integration
  - Responsive layout
- Clean Architecture implementation
  - BLoC pattern for state management
  - Repository pattern
  - Dependency injection

### Dependencies
- flutter_bloc: ^9.0.0
- sqflite: ^2.4.1
- image_picker: ^1.1.2
- camera: ^0.11.1
- google_mlkit_text_recognition: ^0.14.0
- pdf: ^3.11.2
- flutter_email_sender: ^7.0.0
- archive: ^4.0.2
- shared_preferences: ^2.5.2
- flutter_local_notifications: ^18.0.1
- get_it: ^8.0.3