# Zyvi TV - System Architecture & Requirements

## Overview
Zyvi TV is a high-performance cross-platform Live TV and VOD streaming application built for Android and iOS using Flutter. The application relies on Firebase Firestore for real-time channel configuration updates and Firebase Auth for secure management.

## Tech Stack
- **Frontend Framework:** Flutter (Dart)
- **Database / Backend:** Firebase Firestore (Real-time stream links)
- **Authentication:** Firebase Authentication
- **State Management:** Riverpod or Bloc (For instant UI reactivity)
- **Video Player Engine:** Better Player or Video Player with Custom HLS/M3U8 cache layer

## Directory Structure (Flutter Mobile App)
```text
lib/
├── core/
│   ├── theme/          # Dark premium styling configs
│   └── constants/      # App constants, Firestore collection strings
├── data/
│   ├── models/         # ChannelModel, CategoryModel, StreamModel
│   └── providers/      # Firebase Firestore stream listeners
├── presentation/
│   ├── screens/        # Splash, Home, ChannelDetails, VideoPlayer, Settings
│   └── widgets/        # Custom cards, shimmer loaders, interactive sheets
└── main.dart           # Firebase initialization & entry point

Performance Metrics Required
Zero-Lag UI: No synchronous blocking operations on the main UI thread during navigation.

Aggressive Image/Data Caching: Use CachedNetworkImage and local data layer streaming to ensure immediate rendering.

Optimized Stream Boot Time: Player must initialize asynchronously with pre-buffering turned on.


