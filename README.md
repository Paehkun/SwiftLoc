# SwiftLoc: Smart Circle Tracking System 🛰️

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**SwiftLoc** is a high-performance real-time location tracking application built with **Flutter**. It enables users to create "Circles" to monitor family and friends with high precision, featuring smooth map transitions and intelligent background battery management.

---

## 🌟 Key Features

- 📍 **Real-time Live Tracking** – Monitor circle members with millisecond-accurate updates.
- ⚡ **Silent Remote Trigger** – "Ping" a member's device to force a location update even if the app is in the background.
- 🏎️ **Smooth Map Animations** – Experience fluid marker movements powered by `flutter_map_animations`.
- 🔋 **Battery-Aware Logic** – Intelligent heartbeat system (10-min idle / 30-sec moving) to preserve battery life.
- 📱 **Interactive UI** – Modern Draggable Bottom Sheet for quick access to member status and battery levels.

---

## 🛠️ Technology Stack

| Category | Technology |
| :--- | :--- |
| **Mobile Framework** | Flutter |
| **Map Provider** | Flutter Map (CartoDB Voyager) |
| **Backend / Cloud** | Firebase (Realtime Database, FCM) |
| **Animations** | TickerProvider & Flutter Map Animations |
| **State Management** | Provider / Bloc (Optional - based on your setup) |

---

## 📐 System Architecture

SwiftLoc is built with scalability in mind, separating concerns into clear layers:

- **Presentation Layer**: Custom Markers, Interactive Maps, and Draggable Sheets.
- **Service Layer**: Handles Location Streams, Geofencing, and Firebase Sync.
- **Security Layer**: Uses `.env` and Firebase Rules to protect user data.

---

## ⚙️ Installation & Setup

> [!IMPORTANT]
> For security reasons, sensitive files like `google-services.json`, `GoogleService-Info.plist`, and `.env` are **not included** in this repository.

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/Paehkun/SwiftLoc.git](https://github.com/Paehkun/SwiftLoc.git)

2. **Navigate to the project folder:**

   ```bash

    cd swiftloc

3. **Configure Environment Variables: Create a .env file in the root directory and add your keys:**
   ```bash

    MAP_URL=https://{s}[.basemaps.cartocdn.com/rastertiles/voyager/](https://.basemaps.cartocdn.com/rastertiles/voyager/){z}/{x}/{y}{r}.png
    FIREBASE_DB_URL=your_firebase_database_url

4. **Add Firebase Config:**

   ```bash

    Place your google-services.json in android/app/.

    Place your GoogleService-Info.plist in ios/Runner/.

5. **Install dependencies:**

   ```bash

    flutter pub get

6. **Build & Run:**

   ```bash

    flutter run

## 📁 Repository Structure
```Plaintext

lib/
├── services/      # Location services, Firebase logic, & Heartbeat timer
├── utils/         # Map helpers, Marker builders, & UI Constants
├── widgets/       # Custom Bottom Sheets, ListTiles, & Buttons
├── screens/       # Main Map Screen & Navigation logic
└── main.dart      # App initialization & Background Service setup