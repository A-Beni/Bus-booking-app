# TEBOOKA – Real-Time Bus Booking App

**TEBOOKA** is a real-time bus ticketing app designed for efficient, secure, and user-friendly transportation booking in Rwanda. Built using **Flutter** and **Firebase**, the app allows passengers to book bus seats in advance, view nearby drivers, select seats visually, and receive digital tickets instantly.

---

## ✨ Features

* 🔐 **Email-based Authentication**

  * Sign up and log in via email & password.
  * Email verification is enforced for secure access.
  * Forgot password & email verification resending supported.

* 🗘️ **Map Integration**

  * View nearby available buses (drivers) based on geolocation.
  * Tap a driver to view details and proceed with booking.

* 🎟️ **Seat Selection**

  * Visual 3D seat layout for intuitive selection.
  * Real-time seat availability to avoid double booking.
  * Dynamic seat count and booking restriction (e.g. max N seats).

* 🧏️ **Booking Summary & Confirmation**

  * View trip summary, driver info, distance, and ETA.
  * Cancel or edit bookings (within a 10-minute window before departure).
  * Booking generates a digital ticket with QR code.


---

## 🧑‍💻 Tech Stack

| Category             | Tools & Libraries                         |
| -------------------- | ----------------------------------------- |
| Framework            | Flutter                                   |
| Backend-as-a-Service | Firebase (Auth, Firestore, Dynamic Links) |
| Maps & Location      | Google Maps API                           |
| State Management     | `setState` (light), FutureBuilder         |
| Seat Selection       | Custom widgets + Grid layout              |
| Authentication       | FirebaseAuth with email/password          |

---

## 🔐 Authentication Flow

* User signs up with email → Receives verification email.
* Cannot log in unless the email is verified.
* Can resend verification link or reset password.
* Firebase handles session state and security.

---

## 🧭 Navigation Flow

```
SignInPage/RegisterPage
    ↓
HomePage (Google Maps + Nearby Buses)
    ↓
MapPage (Driver List + Distance & ETA)
    ↓
BookingPage (Trip Summary, Select Seats, Confirm)
    ↓
TicketPage (Digital Ticket Display with QR)
```

---

## 📦 Firestore Collections Overview

* **users**:

  * `uid`, `email`, `displayName`

* **drivers**:

  * `driverId`, `name`, `phone`, `location`, `availability`

* **tickets**:

  * `passengerId`, `from`, `to`, `tripDate`, `tripTime`, `seatNumber`, `driverId`, `timestamp`, `fare`

---

## 📲 Firebase Configuration & Deployment

### 🔧 Firebase Setup

1. Create a Firebase Project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable:

   * **Authentication > Email/Password**
   * **Firestore Database**
   * **Firebase Dynamic Links** (optional for future deep linking)
3. Add your Android/iOS app:

   * Use your app's package name (`com.adoris.tebooka`)
   * Download the `google-services.json` or `GoogleService-Info.plist` file and place it in your project

### 🚀 Deploy the App

1. Run `flutter build apk` for Android

2. Use `flutterfire configure` to link Firebase to the Flutter app

3. Deploy your Firestore rules and indexes:

   ```bash
   firebase deploy --only firestore
   ```

4. Use Firebase Hosting (optional) if building a Flutter web version

---

## 📅 Contributors

* Adoris Ngoga

---

🚀 **Installation Instructions**
You can install Tebooka in one of two ways:

Option 1: Install APK (Recommended for End-Users)
Download the latest APK file from the Releases section or from this direct link (insert your deployed link here).

On your Android device:

Open Settings > Security.

Enable Install from Unknown Sources.

Open the downloaded APK and follow the on-screen instructions to install.

Launch Tebooka and sign in with your email to begin booking!

Option 2: Run from Source (For Developers)
Clone the repo:


git clone https://github.com/your-username/tebooka.git
cd tebooka
Install Flutter dependencies:


flutter pub get
Connect a device or start an emulator, then run:

bash
Copy
Edit
flutter run
Firebase Configuration:

Ensure you’ve set up google-services.json in android/app/.

Set up Firebase project and enable required services (Auth, Firestore, Maps).

For development support, refer to the /docs directory or contact the maintainers.

**📄 License, Copyright & Privacy Policy — Tebooka**

**⚖️ End-User License Agreement (EULA)**

By installing, accessing, or using Tebooka, you agree to be bound by the terms of this End-User License Agreement. If you do not agree to the terms of this agreement, do not install or use the application.

License Grant: Tebooka is licensed, not sold. You are granted a limited, non-transferable, revocable, non-exclusive license to download, install, and use the app for personal, non-commercial use.

**Restrictions**: You may not:

Reverse engineer, decompile, or disassemble any part of the app.

Distribute or sublicense the application to others.

Use the app for any unlawful purpose.

Violation of these terms may result in termination of access and possible legal action.

© Copyright Notice
Copyright © 2025 Tebooka Team. All rights reserved.

This project, including all its source code, documentation, designs, and media assets, is the intellectual property of the Tebooka Team.

Unauthorized copying, reuse, or distribution of the codebase or its elements is strictly prohibited without express written permission.

**🔒 Privacy Policy**

Tebooka respects and protects your privacy. By using this app, you agree to the collection and use of data in accordance with this policy:

What We Collect:

Your email address and authentication details (via Firebase).

Location data (used to find nearby buses and drivers).

Booking details such as route, time, and seat selection.

How We Use It:

To improve your travel experience, suggest nearby drivers, and manage bookings in real time.

We do not sell, rent, or share your personal data with third parties for marketing purposes.

Data Storage:

All data is securely stored in Google Firebase and encrypted in transit.

User Rights:

You may request deletion of your data by contacting the Tebooka support team via the app or email.

