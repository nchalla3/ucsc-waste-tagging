# UCSC Waste Tagging App

This is the initial MVP of a project tasked to me by the UCSC Sustainability Office: an AI-powered waste auditing application that uses machine learning to assist in determining the state of campus waste sorting. 

My initial plan is to start by creating a simple mobile application where users can upload a variety of images of campus trash and tag it with data regarding the types of contaminants/waste in the dumpsters. The goal is to crowdsource this app to sustainability-motivated UCSC students, with the idea of creating a large dataset to train an AI model that can eventually perform this analysis independent of manual tagging.

From here, I will create a model trained on the aforementioned data to be able to utilize computer vision to automatically determine the levels of contamination in a given campus dumpster using PyTorch and TensorFlow to get a better understanding of how accurately garbage and recycling are sorted in their respective bins on campus.

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed on your system:

#### Required for all platforms:
- **Flutter SDK** (3.8.1 or higher) - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Git** - [Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- **Firebase CLI** - [Installation Guide](https://firebase.google.com/docs/cli#install_the_firebase_cli)

#### Platform-specific requirements:

**For iOS development (macOS only):**
- **Xcode** (latest stable version) - Available on Mac App Store
- **iOS Simulator** (included with Xcode)
- **CocoaPods** - Install with: `sudo gem install cocoapods`
- **Apple Developer Account** (for device deployment)

**For Android development:**
- **Android Studio** - [Download](https://developer.android.com/studio)
- **Android SDK** (API level 21 or higher)
- **Java JDK** (version 11 or higher)
- **Android device** or **Android Emulator**

**For Web development:**
- **Chrome** or **Edge** (recommended browsers for development)

### 📱 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nchalla3/ucsc-waste-tagging.git
   cd ucsc-waste-tagging
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify your Flutter installation:**
   ```bash
   flutter doctor
   ```
   Resolve any issues shown by `flutter doctor` before proceeding.

### 🔥 Firebase Setup

This app requires Firebase for authentication, data storage, and image hosting. Follow these steps:

1. **Create a Firebase project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use an existing one
   - Enable the following services:
     - Authentication (Email/Password and Google Sign-in)
     - Cloud Firestore
     - Cloud Storage

2. **Configure Firebase for your platforms:**

   **For Android:**
   ```bash
   # Install and configure Firebase CLI if not already done
   npm install -g firebase-tools
   firebase login
   
   # Initialize Firebase in your project
   firebase init
   
   # Generate Android configuration
   flutterfire configure --project=your-project-id
   ```
   This will create `android/app/google-services.json`

   **For iOS:**
   ```bash
   # Use the same flutterfire command, it will also generate iOS config
   flutterfire configure --project=your-project-id
   ```
   This will create `ios/Runner/GoogleService-Info.plist`

   **For Web:**
   The same `flutterfire configure` command will update `lib/firebase_options.dart` with web configuration.

3. **Enable Authentication providers:**
   - In Firebase Console, go to Authentication > Sign-in method
   - Enable "Email/Password" provider
   - Enable "Google" provider and configure OAuth consent screen

4. **Set up Firestore security rules:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /waste_reports/{document} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

5. **Set up Storage security rules:**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /uploads/{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### ▶️ Running the App

#### iOS (macOS only)

1. **Open iOS Simulator or connect an iOS device**

2. **Run the app:**
   ```bash
   flutter run -d ios
   ```

3. **For physical device deployment:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your development team
   - Choose your connected device
   - Run from Xcode or use `flutter run`

#### Android

1. **Start an Android emulator or connect an Android device**
   ```bash
   # List available devices
   flutter devices
   
   # Start an emulator (if you have one configured)
   flutter emulators --launch <emulator_id>
   ```

2. **Run the app:**
   ```bash
   flutter run -d android
   ```

#### Web

1. **Run the app in Chrome:**
   ```bash
   flutter run -d chrome
   ```

2. **Build for web deployment:**
   ```bash
   flutter build web
   ```
   The built files will be in the `build/web` directory.

### 🏗️ Development Workflow

#### Running in development mode:
```bash
# Hot reload development
flutter run

# Run with specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

#### Building for production:

**Android APK:**
```bash
flutter build apk
```

**Android App Bundle (recommended for Google Play):**
```bash
flutter build appbundle
```

**iOS (requires macOS and Xcode):**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

### 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests (if available)
flutter drive --target=test_driver/app.dart
```

### 📋 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── screens/                  # UI screens
│   ├── auth/                # Authentication screens
│   └── home/                # Main app screens
├── services/                # Business logic and API calls
├── widgets/                 # Reusable UI components
└── wrappers/                # App-level wrappers
```

### 🐛 Troubleshooting

#### Common Issues:

**Flutter Doctor Issues:**
- Ensure all required tools are installed and in your PATH
- For Android: Make sure ANDROID_HOME environment variable is set
- For iOS: Ensure Xcode command line tools are installed: `xcode-select --install`

**Firebase Configuration:**
- Verify that `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in the correct locations
- Check that your Firebase project has the required services enabled
- Ensure your app's package name matches your Firebase project configuration

**Build Errors:**
- Clean your build: `flutter clean && flutter pub get`
- For iOS: `cd ios && pod install && cd ..`
- For Android: Delete `android/.gradle` folder and rebuild

**Authentication Issues:**
- Verify OAuth consent screen is configured in Google Cloud Console
- Check that SHA-1 fingerprints are added for Android (for Google Sign-in)
- Ensure your domain is authorized in Firebase Authentication settings

#### Platform-specific Troubleshooting:

**iOS:**
- CocoaPods issues: `cd ios && pod repo update && pod install`
- Provisioning profile errors: Check signing settings in Xcode
- Simulator not found: Update Xcode or install additional simulators

**Android:**
- Gradle build failures: Update Android Gradle Plugin and Gradle wrapper
- SDK license issues: Run `flutter doctor --android-licenses`
- Emulator performance: Enable hardware acceleration in BIOS/UEFI

**Web:**
- CORS issues: Use `flutter run -d chrome --web-renderer html`
- Firebase configuration: Ensure web app is properly configured in Firebase Console

### 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes and test thoroughly
4. Commit your changes: `git commit -m "Add new feature"`
5. Push to your branch: `git push origin feature/new-feature`
6. Submit a pull request

### 📄 License

This project is developed for the UCSC Sustainability Office. Please contact the project maintainer for licensing information.

### 📞 Support

For technical issues or questions about the project, please:
1. Check the troubleshooting section above
2. Search existing issues in the repository
3. Create a new issue with detailed information about your problem

### 🏫 About UCSC Sustainability Office

This project is developed in partnership with the UC Santa Cruz Sustainability Office to support campus waste reduction and sustainability goals.
