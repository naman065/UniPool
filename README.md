<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android"/>
<img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS"/>


#
<br/><br/>

# 🚖 UniPools

### Campus ride-sharing, one place.

*A mobile application for IIT Kanpur students to coordinate shared rides — post a ride, find one going your way, and chat with co-passengers in real time.*

<br/>

[Features](#-features) · [Screenshots](#-screenshots) · [Tech Stack](#-tech-stack) · [Getting Started](#-getting-started) · [Project Structure](#-project-structure) · [Database Schema](#-database-schema) · [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Firebase Setup](#firebase-setup)
  - [Running the App](#running-the-app)
- [Project Structure](#-project-structure)
- [Database Schema](#-database-schema)
- [Predefined Locations](#-predefined-locations)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [Team](#-team)
- [License](#-license)

---

## 🎯 About

UniPool is a cross-platform mobile application built for the IIT Kanpur campus community. Students regularly share auto-rickshaws, cabs, and other vehicles between campus and the city. Coordinating these rides — especially across a large student population — is typically done through fragmented WhatsApp groups or word of mouth.

UniPool solves this by providing a single, structured platform where a student can:

- **Post a ride** they are already booking, so others heading the same way can join.
- **Browse open rides** and filter by destination to find one that fits their plans.
- **Chat in real time** with everyone in the ride to coordinate pick-up times and logistics.
- **Build a trust profile** that reflects their history of completed rides.

> Built as a course project for **CS253 — Software Development and Engineering**, IIT Kanpur.

---

## ✨ Features

### 🔐 Authentication
- Email and password sign-in with mandatory email verification
- Google OAuth 2.0 one-tap sign-in
- Password reset via email link
- Persistent sessions — stay signed in across app restarts

### 🏠 Home Dashboard
- Personalised greeting with quick-access tiles
- One-tap navigation to all core screens
- Sign-out from anywhere

### 🚗 Ride Creation
- Select source and destination from **27 predefined campus and city locations**
- Choose a departure date via a date picker (today or future only)
- Source and destination are validated to be different before submission
- Ride is posted instantly and visible to all users in real time

### 🔍 Ride Discovery
- Browse all open rides in a live-updating feed
- Filter rides by destination with a single dropdown selection
- Tap any ride card to see full details and the leader's trust profile
- Join any ride's group chat with one tap

### 💬 Real-time Group Chat
- Per-ride group chat backed by Firestore real-time listeners
- Messages stream instantly to all participants without any page refresh
- Sending a message automatically registers you as a ride participant
- Clear visual distinction between your messages and others'

### 📋 My Rides
- **I Am Leading** tab — all rides you have posted, with current status
- **I Joined** tab — all rides you have participated in via chat
- Mark rides as **Complete** to update your trust score
- **Delete** rides you no longer need, with a confirmation step
- Jump into any ride's chat directly from this screen

### 👤 Profile Management
- Upload and update a profile photo from the device gallery
- Edit your display name at any time
- View your **Rides Completed** count — a public trust indicator

---


---

## 🛠 Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Dart | SDK ^3.10.7 |
| UI Framework | Flutter (Material Design 3) | Latest stable |
| Authentication | Firebase Authentication | ^6.1.3 |
| Database | Cloud Firestore (NoSQL) | ^6.1.1 |
| File Storage | Firebase Storage | ^13.0.5 |
| Google Sign-In | google_sign_in | ^6.2.1 |
| Image Picker | image_picker | ^1.0.4 |
| Date Formatting | intl | ^0.20.2 |
| ID Generation | uuid | ^4.2.1 |
| Build System | Gradle (Android) / Xcode (iOS) | — |

---

## 🚀 Getting Started

### Prerequisites

Ensure the following are installed and configured on your machine:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) **≥ 3.10.7**
- [Dart SDK](https://dart.dev/get-dart) (bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with the Flutter and Dart extensions
- [Git](https://git-scm.com/)
- A Firebase project (see [Firebase Setup](#firebase-setup) below)

Verify your Flutter installation:

```bash
flutter doctor
```

All items should show a green check. Resolve any issues before proceeding.

---

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/your-group/unipool.git
cd unipool
```

**2. Install dependencies**

```bash
flutter pub get
```

---


---

### Running the App

**Development mode (with hot reload)**

```bash
flutter run
```

**Run on a specific device**

```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

**Build a release APK (Android)**

```bash
flutter build apk --release
```

The output APK is located at `build/app/outputs/flutter-apk/app-release.apk`.


## 📁 Project Structure

```
unipool/
│
├── android/                    # Android build scaffolding (Gradle)
│   └── app/
│       └── google-services.json  ← place your Firebase config here
│
├── ios/                        # iOS build scaffolding (Xcode)
│   └── Runner/
│       └── GoogleService-Info.plist  ← place your Firebase config here
│
├── lib/                        # ★ All application source code lives here
│   │
│   ├── main.dart               # Entry point — initialises Firebase, mounts app,
│   │                           # handles auth-state routing via StreamBuilder
│   │
│   ├── data/
│   │   └── ride_locations.dart # 27 predefined campus + city location constants
│   │
│   ├── screens/
│   │   ├── auth_screen.dart        # Sign-in, sign-up, Google OAuth, password reset
│   │   ├── home_screen.dart        # Post-auth dashboard and navigation hub
│   │   ├── create_ride_screen.dart # Ride creation form (source, dest, date)
│   │   ├── find_ride_screen.dart   # Live ride discovery with destination filter
│   │   ├── my_rides_screen.dart    # Tabbed view: rides led + rides joined
│   │   ├── chat_screen.dart        # Per-ride real-time group chat
│   │   └── profile_screen.dart     # Profile photo, display name, rides-completed
│   │
│   ├── theme/
│   │   └── app_theme.dart      # AppColors palette, gradients, AppTheme factory
│   │
│   └── widgets/
│       └── app_ui.dart         # Shared reusable widgets:
│                               #   AppGradientBackground, AppPageHeader,
│                               #   AppSurfaceCard, AppPill, AppIconBadge,
│                               #   AppPrimaryButton, AppEmptyState,
│                               #   showAppSnackBar
│
├── test/                       # Unit and widget tests
├── pubspec.yaml                # Dart/Flutter dependency manifest
└── .gitignore
```

---

## 🗄 Database Schema

UniPool uses **Cloud Firestore** (NoSQL document database). The data model consists of two top-level collections and one sub-collection.


## 🗺 Roadmap

- [ ] **Google Maps Integration** — Display the ride route on an embedded map; live location sharing during the journey
- [ ] **Push Notifications (FCM)** — Notify participants of new chat messages when the app is in the background
- [ ] **Fare Splitting** — Enter the total fare after ride completion; compute each participant's share
- [ ] **Peer Ratings** — Post-ride 1–5 star ratings to build a comprehensive trust score
- [ ] **Recurring Rides** — Allow leaders to post rides on a repeating schedule (e.g. every weekday)
- [ ] **Seat Count** — Let leaders specify the number of available seats in the ride

---

## 🤝 Contributing

Contributions are welcome. Please follow the steps below:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature-name`
3. **Commit** your changes with a descriptive message: `git commit -m "feat: add fare splitting screen"`
4. **Push** to your branch: `git push origin feature/your-feature-name`
5. **Open a Pull Request** against the `main` branch

Please ensure `flutter analyze` reports no issues and existing tests pass before opening a PR.

---

## 👥 Team

Developed by **Group 16- Undefined_Behaviour**
Department of Computer Science and Engineering, IIT Kanpur
Course: **CS253 — Software Development and Engineering**



---

## 📄 License

This project is for academic purposes under IIT Kanpur's CS253 course. All rights reserved by the team members listed above.

---

<div align="center">
  <sub>Built with ❤️ at IIT Kanpur</sub>
</div>
