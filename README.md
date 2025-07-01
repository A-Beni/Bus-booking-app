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

* 📩 **Email Notifications**

  * Confirmation sent via email after booking.
  * Driver gets notified of new passenger.

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

## ✨ License

This project is licensed under the MIT License.
