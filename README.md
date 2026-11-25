# KVM Workforce Management (KVM_WFM)

An enterprise Workforce Management & Reverse Vending Machine (RVM) Fleet Tracking ecosystem built for live field operations.

---

## 🏗️ Architecture Overview

The repository is organized into three components:

### 1. `app/` — Flutter Multi-Platform App (Android & Web)
- **Fleet Monitor Dashboard**: Real-time supervision of 13+ reverse vending machine locations across Tamil Nadu (Vellore, Arani, Bagayam, etc.).
- **Staff Attendance & GPS Verification**: Geo-tagged shift check-in and check-out with automatic coordinate verification.
- **Bottle Collection & Crate Packing**: Real-time bottle inflow logging, bin clearance, crate packing (25 bottles/crate), and truck gate pass dispatch.
- **Float & Cash Reconciliation**: Audit physical cash given to customers vs. machine deposits with digital QR payout verification.
- **Bilingual Interface**: Seamless instant toggle between English and Tamil (தமிழ்).
- **Offline Persistence**: Local cache (`SharedPreferences`) merged automatically with cloud sync.

### 2. `hostinger_php_api/` — Production Cloud REST API
- Production REST backend running on Hostinger (`https://wfm-api.e2s2.in/api`).
- Handles telemetry endpoints:
  - `GET /stations` & `PUT /stations/{id}`: Station management & worker assignment.
  - `POST /attendance/checkin` & `checkout`: GPS-stamped attendance logs.
  - `POST /fleet/readings`: Real-time bottle intake and packed crate metrics.
  - `POST /audit/cash`: Customer cash payouts vs. machine reimbursements.
  - `GET /employees` & `POST /employees`: Corporate employee directory & credentials.

### 3. `backend/` — Node.js & Express Service
- Microservice for HR onboarding workflow and automated credential emailing via Resend API.
- Direct database schema migrations (`schema.sql`).

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.24.0`
- **Dart SDK**: `>= 3.5.0`
- **Node.js**: `>= 18.0.0` (for backend service)
- **PHP**: `>= 8.1` & **MySQL** (for API deployment)

### Running the Flutter App
```bash
cd app
flutter pub get
flutter run -d chrome      # Web
flutter run -d <device-id> # Android / iOS
```

### Building Release Artifacts
```bash
# Android Release APK (no tree-shake icons required)
flutter build apk --release --no-tree-shake-icons

# Web Release Bundle
flutter build web --release --no-tree-shake-icons
```

---

## 📄 License
Proprietary — Developed for KVM Workforce Management Operations.
