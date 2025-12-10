# Digital Detox 📱🧘

A Flutter mobile application to help users manage screen time and promote healthy digital habits.

## Features

- 🔐 **Firebase Authentication** - Secure email/password login and registration
- 👤 **User Profile Management** - Personal information and preferences
- ⏱️ **Screen Time Management** - Set and track digital usage limits
- 🎯 **Digital Wellness Goals** - Encourage healthy digital habits
- 📊 **Progress Tracking** - Monitor your digital detox journey

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. Clone the repository:
```bash
git clone https://github.com/vedikalohiya/digital_detox.git
cd digital_detox
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication with Email/Password
   - Add Android app with package name: `com.package.digitaldetox`
   - Download `google-services.json` and place in `android/app/`
   - Copy `.env.example` to `.env` and fill in your Firebase keys
   - See [FIREBASE_SECURITY_SETUP.md](FIREBASE_SECURITY_SETUP.md) for detailed instructions

4. Run the app:
```bash
flutter run
```

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── auth_service.dart         # Authentication service
├── user_model.dart          # User data model
├── login.dart               # Login screen
├── signup.dart              # Registration screens
├── dashboard.dart           # Main dashboard
└── ...
```

## Technologies Used
- **Flutter** - Cross-platform mobile framework
- **Firebase Auth** - User authentication
- **Cloud Firestore** - User data storage
- **Dart** - Programming language

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
This project is licensed under the MIT License.
