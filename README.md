# CliniTrack

CliniTrack is a Flutter-based clinic management application designed to help healthcare professionals manage daily clinic activities in one place. The application provides an organized interface for managing patients, appointments, medical records, prescriptions, and profile information.

> **Note:** CliniTrack is currently a UI-focused project that uses local dummy data and simulated authentication. No backend or real medical database is currently connected.

## Features

### Authentication

- Login and registration screens
- UI-only authentication
- Users can access the dashboard regardless of the entered credentials
- Navigation between Login and Registration screens

### Dashboard

The dashboard provides a quick overview of clinic activity, including:

- Total patients
- Total appointments
- Total prescriptions
- Today's appointments
- Quick access to major sections of the application

### Patient Management

Users can:

- View and search patients
- Add new patients
- Edit patient information
- View detailed patient profiles

Patient information includes:

- Name and age
- Gender and contact information
- Blood group
- Medical history
- Allergies
- Previous visit information

### Appointment Management

Users can manage and view:

- Today's appointments
- Upcoming appointments
- Completed appointments
- Appointment date and time
- Patient information
- Reason for visit
- Appointment status

Appointments for the current day are generated dynamically so the **Today's Appointments** section remains relevant.

### Medical Records

Patient medical information is organized into expandable sections, making records easier to read and navigate.

### Prescriptions

Users can view and manage prescription information associated with patients.

### Profile

The profile section displays:

- Doctor name and specialty
- Biography
- Qualifications and experience
- Clinic address
- License number
- Email and phone number
- Activity statistics

Users can also update their information through the Edit Profile screen.

### Theme Support

CliniTrack supports both **Light Mode** and **Dark Mode**, using centralized colors and theme-aware components for a consistent experience.

## Dummy Data

The application includes sample data for demonstration:

- **30 Patients**
- **30 Appointments**
- Today's appointments
- Upcoming appointments
- Completed appointments
- Sample prescriptions and medical records

All information is dummy data and is intended only to demonstrate the application's functionality.

## State Management and Local Storage

CliniTrack uses:

- **Provider** for state management
- **SharedPreferences** for local data persistence

Providers manage application data such as authentication, patients, appointments, prescriptions, and theme settings.

## Tech Stack

- Flutter
- Dart
- Provider
- SharedPreferences
- Material Design

## Project Structure

    lib/
    ├── main.dart
    ├── models/
    ├── providers/
    ├── screens/
    ├── widgets/
    └── utils/

## Getting Started

### Prerequisites

Make sure you have:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- An Android Emulator or physical device

### Installation

Clone the repository:

    git clone <your-repository-url>

Navigate to the project directory:

    cd clinitrack

Install dependencies:

    flutter pub get

Run the application:

    flutter run

## Future Improvements

Possible future improvements include:

- Backend and database integration
- Real authentication
- Firebase or REST API integration
- User roles such as Doctor, Nurse, and Admin
- Appointment reminders and notifications
- Advanced search and filtering
- PDF prescription generation
- Medical report uploads
- Analytics and reports

## Disclaimer

CliniTrack is an educational and demonstration project. All patient information used in the application is dummy data and should not be used for real medical purposes.

## Author

**Ishfak Akbar Nahian**  
Aspiring Software Engineer
