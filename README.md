🚌 TEBOOKA – Real-Time Bus Booking App
TEBOOKA is a real-time Flutter-based bus booking application designed to simplify public transport for users in Kigali, Rwanda. It enables users to register with email, view available buses on a map, select seats, confirm bookings, and view their tickets.

📱 Features
User Authentication

Email and password registration & login (Firebase Auth)

Email verification (Firebase Email Templates)

Password reset

Remember me option using SharedPreferences

Booking System

Real-time driver & bus discovery

Seat selection with reserved seats shown

Booking confirmation and Firestore ticket creation

Cancel & Edit booking (Edit allowed only 10 minutes before departure)

Ticket Management

View ticket after booking

Ticket includes QR code, fare, seat number, trip info, and driver details

Driver Integration

Driver details (name, phone) loaded from Firestore

Driver gets notified via data storage (future: push notification)


🔐 Firebase Setup Instructions
Create Firebase Project

Go to Firebase Console

Create a project called TEBOOKA

Add an Android app with package name com.adoris.tebooka

Enable Authentication

Go to Authentication > Sign-in Method

Enable Email/Password

Optionally set up email templates for verification

Enable Firestore

Go to Firestore Database > Create database

Choose test mode for development

Set security rules properly for production

Firebase Dynamic Links (for email verification)

Go to Engage > Dynamic Links

Create domain: https://tebooka.page.link

Add it to the email verification template

Add Firebase SDK to Flutter

In Flutter project root:

bash
Copy
Edit
flutter pub add firebase_core firebase_auth cloud_firestore firebase_dynamic_links shared_preferences
Initialize Firebase in main.dart

dart
Copy
Edit
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
▶️ How to Run the App Locally
Clone the Repository

bash
Copy
Edit
git clone https://github.com/your-username/tebooka.git
cd tebooka
Install Packages

bash
Copy
Edit
flutter pub get
Run the App

bash
Copy
Edit
flutter run
🚀 Firebase Hosting (Optional for Admin Panel or Web Version)
Note: If deploying a web admin or Flutter web version.

Install Firebase CLI

bash
Copy
Edit
npm install -g firebase-tools
firebase login
Initialize Hosting

bash
Copy
Edit
firebase init hosting
Build Web App

bash
Copy
Edit
flutter build web
Deploy

bash
Copy
Edit
firebase deploy
📦 Firestore Collections (Schema)
drivers
json
Copy
Edit
{
  "name": "John Doe",
  "phone": "+250788000000",
  "location": { "lat": 1.94, "lng": 30.06 }
}
tickets
json
Copy
Edit
{
  "passengerId": "uid",
  "from": "Nyabugogo",
  "to": "Kimironko",
  "tripDate": "2025-07-01",
  "tripTime": "12:30",
  "seats": 2,
  "seatNumber": 12,
  "fare": 800.0,
  "driverId": "driverUID",
  "timestamp": "2025-07-01T08:00:00Z"
}
⚙️ Environment Config (Optional)
Create a .env file if needed using flutter_dotenv:

env
Copy
Edit
FIREBASE_API_KEY=xxx
FIREBASE_PROJECT_ID=tebooka
💡 Future Improvements
Push notifications to drivers (using Firebase Messaging)

Payment gateway integration (MTN Mobile Money, Airtel Pay)

Admin dashboard (Flutter Web or React)

Real-time location tracking of buses

Chat between passenger and driver

👤 Contributors
Adoris Ngoga

📄 License
This project is open-source and licensed under the MIT License.

Let me know if you'd like a markdown version of this file for GitHub (README.md) or want it formatted into a PDF or DOCX for submission.
