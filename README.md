# One More Deal 🤝

A structured, searchable, and subscription-based marketplace for real estate brokers and builders.

## Overview

One More Deal is a professional real estate platform designed to streamline the interaction between brokers and builders. It provides a specialized environment for listing, searching, and managing real estate deals within a secure and subscriber-restricted ecosystem.

## Key Features

- **Professional Networking**: A dedicated platform bridging the gap between developers and agents.
- **Structured Listings**: Standardized data entry for clarity and better comparisons.
- **Advanced Search**: Powerful filtering to find exactly what your clients need.
- **Subscription Model**: Ensuring a high-quality, professional-only user base.
- **Clean UI**: Built with Flutter 3 and Material Design 3 for a smooth, premium experience.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, ^3.9.2)
- **UI Design**: Material 3
- **State Management**: (Future: Provider/Bloc/Riverpod)
- **Security**: Environment variables via `flutter_dotenv`

## Getting Started

### Prerequisites

- Flutter SDK (v3.9.2 or higher)
- Android Studio / VS Code with Flutter extension
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yashNiwane/One-More-Deal.git
   cd One-More-Deal
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create a `.env` file in the root directory (refer to `.env.example` if available).
   ```bash
   # Example .env content
   API_URL=https://api.onemoredeal.com
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

## Folder Structure

- `lib/`: Contains the core application logic.
- `android/` & `ios/`: Native configuration folders.
- `assets/`: Global assets including configuration and images.

---

*One More Deal — Bringing clarity to real estate.*
