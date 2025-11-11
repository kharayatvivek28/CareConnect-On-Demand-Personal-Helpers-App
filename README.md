# 🧑‍🔧 CareConnect – On-Demand Personal Helpers

**CareConnect** is a Flutter + Firebase-based service marketplace app that connects users with nearby verified service providers (e.g., appliance repair, beauty, home maintenance, and wellness experts).  
It enables users to explore services, book appointments, manage bookings, and securely make payments — all in one place.

---

## 🚀 Features Implemented

### 👤 **User & Authentication**
- Firebase Authentication for secure login/signup
- Profile management with stored addresses and base city
- Dynamic greeting & personalized home header
- Displays user’s default service address and location

### 🏡 **Home Screen**
- Category-based service filtering with highlight and clear filter option
- Dynamic services fetched from Firestore (`services` collection)
- Bottom modal sheet ("Explore All") to view full service list
- Carousel for promotional offers
- Professional **Customer Feedback Section** (static for now, dynamic planned)
- Floating “Help” button for quick support

### 🛠️ **Service Management**
- Detailed **Service Details Screen** showing service info, description, base price, and addons
- **Confirm Booking Screen** with:
    - Date picker
    - Address auto-selection from user profile
    - Provider filtering (city + profession match)
    - Provider dropdown with live rating & availability
    - Add-ons selection with dynamic total price
    - Firestore booking creation (`bookings` collection)

### 📅 **Booking Management**
- Bookings categorized as:
    - **Active**
    - **Completed**
    - **Cancelled**
- Real-time updates using Firestore streams
- Action buttons for:
    - ✅ Mark as Completed
    - ❌ Cancel Booking
- Confirmation dialogs before status updates
- Bookings instantly move between tabs after status change
- Dynamic provider info fetched via `providerId`

### ⭐ **Feedback System**
- Placeholder UI for customer feedback cards (with name, rating, service type, and review)
- Planned integration with `feedback` Firestore collection for real reviews

### 💳 **Payments**
- Razorpay test payment backend (Express.js) integrated
- Secure order creation & QR code payment screen planned

---

## 🧩 Tech Stack

| Category                      | Technology |
|-------------------------------|-------------|
| **Frontend**                  | Flutter (Dart) |
| **Backend**                   | Firebase Firestore + Firebase Auth |
| **Payment (Planned)**         | Razorpay (Test Mode via Node.js backend) |
| **State Management**          | Flutter Stateful Widgets + Context |
| **Cloud Functions (Planned)** | Firebase Functions |
| **Version Control**           | Git & GitHub |
| **Hosting (Future)**          | Firebase Hosting / Play Store |

---

## 🗂️ Project Structure

```bash
CareConnect/
│
├── android/                  # Android native project files
├── ios/                      # iOS native project files
├── lib/                      # Flutter source code
│   ├── screens/              # All screens (Home, Booking, Profile, etc.)
│   ├── widgets/              # Common reusable widgets
│   ├── utils/                # Utilities, constants, helper functions
│   ├── services/             # Firestore, Auth, Payment integration logic
│   └── main.dart             # Entry point
│
├── assets/                   # Banners, icons, images
│   └── banners/              # Home screen offer banners
│
├── backend/                  # Express.js backend for Razorpay (Test)
│   ├── server.js
│   └── package.json
│
├── pubspec.yaml              # Flutter dependencies
├── .gitignore                # Ignored build & secret files
├── README.md                 # Project documentation
└── .env.example              # Sample environment variables
```

## 🔧 Setup Instructions
### 🪄 1. Clone Repository
 ```bash 
git clone https://github.com/kharayatvivek28/CareConnect.git
cd CareConnect
 ```

### ⚙️ 2. Setup Firebase

- Create a Firebase project in Firebase Console 
- Enable Authentication (Email/Password)
- Enable Cloud Firestore 
- Add an Android and/or iOS app to Firebase 
- Download google-services.json → place inside android/app/ 
- Download GoogleService-Info.plist → place inside ios/Runner/

### 📦 4. Install Dependencies
```bash 
flutter pub get

```

### ▶️ 5. Run the App
```bash
flutter run

```

## 🔒 Firestore Collections Used
| **Collection** | **Description**                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------- |
| `users`        | Stores user information, addresses, and base city for personalized service matching.              |
| `services`     | Contains all available service categories, details, and related add-ons.                          |
| `providers`    | Holds information about service providers, including their profession, city, skills, and ratings. |
| `bookings`     | Tracks user bookings with real-time status updates (Active, Completed, Cancelled).                |
| `feedback`     | Stores customer feedback and ratings for providers *(planned integration)*.                       |

## 🧭 Future Enhancements

- 🔔 Real-time push notifications using Firebase Cloud Messaging 
- 💬 In-app chat between user & provider 
- 📍 Live tracking of provider using GPS 
- 🌐 Multi-city & multi-language support 
- 🧾 Downloadable invoices & advanced payment modes 
- 🧠 AI-based service recommendations 
- 🛠️ Admin dashboard (for service, provider, and feedback management)
- ⭐ Dynamic rating & feedback system connected to Firestore