# 📋 MedScan AI — Development & Feature Upgrade Plan (plan.md)

This document outlines the strategic roadmap, planned architectural updates, and new feature enhancements for **MedScan AI**. Features are categorized into distinct phases based on priority, clinical utility, and implementation complexity.

---

## 🧭 Milestone Overview

| Phase | Focus Area | Key Deliverables | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Accessibility & User Experience** | Sinhala & English TTS, PDF Export, Scan Flashlight | 🟡 Next Up |
| **Phase 2** | **Patient Adherence & Clinical Safety** | Dosage Reminder Alarms, Drug Interaction Checker | ⚪ Planned |
| **Phase 3** | **Offline Support & Localization** | On-device ML Kit OCR fallback, Emergency Directory | ⚪ Planned |
| **Phase 4** | **Production & Security Architecture** | Backend API Gateway, Firebase Auth, Store Compliance | ⚪ Planned |

---

## 🚀 Phase 1: Accessibility & User Experience (High Priority)

### 1.1 Text-to-Speech (TTS) Voice Reader (හඬින් කියවීම)
* **Goal**: Enable elderly or visually impaired patients to listen to medicine instructions in Sinhala or English with a single tap.
* **Target Packages**: `flutter_tts: ^4.2.2`
* **Implementation Plan**:
  - Add TTS audio player controls at the top of both the Sinhala and English tabs in `ResultScreen`.
  - Add individual "Listen" buttons next to crucial cards (Usage Instructions, Precautions, Side Effects).
  - Configure Sinhala (`si-LK` or fallback phonetic engine) and English (`en-US`) voice profiles.
  - Implement play, pause, stop, and speech rate adjustment sliders.

### 1.2 PDF Clinical Summary Export (වෛද්‍ය වාර්තා PDF)
* **Goal**: Generate formatted, printable PDF medical summaries for patients to present to their physician or pharmacist.
* **Target Packages**: `pdf: ^3.11.1`, `printing: ^5.13.2`
* **Implementation Plan**:
  - Build a clean medical PDF template with patient metadata, medicine photo, brand, active compounds, and dosage schedule.
  - Support bilingual PDF rendering (embedding Noto Sans Sinhala TTF fonts).
  - Provide 1-tap "Save to Files" and "Print Report" action in the result screen.

### 1.3 Camera Flashlight & Real-Time Focus Assist
* **Goal**: Improve OCR accuracy in low-light environments and prevent reflective foil glare.
* **Target Packages**: Integrated with `camera` or `image_picker` camera intents.
* **Implementation Plan**:
  - Add camera torch/flashlight toggle overlay during photo capture.
  - Add on-screen gridlines showing optimal pill alignment and framing guide.

---

## 💊 Phase 2: Patient Adherence & Clinical Safety (Medium Priority)

### 2.1 Smart Dosage Reminders & Alarms (බෙහෙත් වේලාවන් මතක් කිරීම්)
* **Goal**: Automatically convert AI-extracted dosage intervals into scheduled device alarms and push notifications.
* **Target Packages**: `flutter_local_notifications: ^18.0.1`, `timezone: ^0.10.0`
* **Implementation Plan**:
  - After scanning a medicine (e.g., "1 tablet every 8 hours after meals"), prompt user: *"Set daily reminders for this medication?"*.
  - User selects meal times (Breakfast, Lunch, Dinner, Bedtime).
  - System schedules persistent recurring local alarms that fire even when the app is closed.
  - Track taken doses with a "Mark as Taken" button in notifications.

### 2.2 Multi-Medicine Drug Interaction Checker (ඖෂධ අන්තර්ක්‍රියා පරීක්ෂාව)
* **Goal**: Prevent dangerous drug-drug interactions when taking multiple prescriptions concurrently.
* **Implementation Plan**:
  - Add a **"Compare / Check Interaction"** mode in `HomeScreen`.
  - Allow scanning 2 or more medicines in sequence.
  - Send multimodal prompt to Gemini: *"Analyze these 2 medicines. Identify contraindications, adverse interactions, or increased toxicity risks if taken concurrently."*
  - Display an **Interaction Risk Meter**: `Safe (Green)`, `Caution (Yellow)`, `High Risk / Contraindicated (Red)`.

### 2.3 Expiry Date Tracker & Medicine Cabinet
* **Goal**: Catalog scanned medicines in a virtual "Medicine Cabinet" and alert users before expiry.
* **Implementation Plan**:
  - Prompt vision AI to specifically extract Batch Number and Expiration Date (EXP / B.No).
  - Store active medicines in a local database (`sqflite` or `hive`).
  - Send notifications 30 days and 7 days prior to medicine expiration.

---

## 🏥 Phase 3: Offline Support & Local Directory (Enhancement)

### 3.1 Offline OCR Fallback via Google ML Kit
* **Goal**: Provide basic brand and text identification even when the device has no internet connection.
* **Target Packages**: `google_mlkit_text_recognition: ^0.14.0`
* **Implementation Plan**:
  - Detect network connectivity using `connectivity_plus`.
  - When offline: run on-device ML Kit OCR to identify raw text, brand name, and dosage numbers.
  - Cache common Sri Lankan essential medicines locally (e.g., Paracetamol, Amoxicillin, Metformin, Losartan).
  - Queue full multimodal Gemini analysis to run automatically once network connectivity is restored.

### 3.2 Sri Lanka Emergency & Pharmacy Helpline Directory
* **Goal**: Instant access to emergency clinical poison centers and verified pharmacies.
* **Target Packages**: `url_launcher: ^6.3.1`
* **Implementation Plan**:
  - Dedicated Emergency Card in Home Drawer:
    - **National Poisons Information Centre (Colombo)**: `011-2686143` (1-tap dial).
    - **1990 Suwa Seriya Ambulance Service**: `1990` (1-tap dial).
    - **Government Medical Information**: `1959`.
  - Google Maps integration to navigate to the nearest registered pharmacy.

---

## 🔒 Phase 4: Production, Security & Play Store Release

### 4.1 Backend Proxy Architecture (API Key Security)
* **Goal**: Protect Gemini API keys and enforce rate limiting before public release on Google Play Store & Apple App Store.
* **Implementation Plan**:
  - Deploy a lightweight serverless backend proxy (Firebase Cloud Functions / Google Cloud Run / Node.js).
  - Client sends image payload with secure app check tokens (`firebase_app_check`).
  - Backend securely invokes Gemini 1.5 Flash using environment secrets.
  - Prevents reverse-engineering or quota abuse of developer API keys.

### 4.2 Medical Compliance & Legal Disclaimer Onboarding
* **Goal**: Protect developers from medical liability and adhere to Google Play Medical Apps Policy.
* **Implementation Plan**:
  - Add a one-time onboarding Terms of Service & Medical Disclaimer screen on first app launch.
  - User must actively accept: *"I acknowledge MedScan AI is an educational assistance tool and not a substitute for professional medical diagnosis or prescription."*

---

## 🛠️ Implementation Checklist

- [x] **Task 1.1**: Integrated `flutter_tts` and built Sinhala/English Voice Reader bar in `result_screen.dart` via `TtsService`.
- [x] **Task 1.2**: Added `pdf` and `printing` to generate and print hospital-grade clinical summary PDFs via `PdfExportService`.
- [x] **Task 1.3**: Added camera flash/torch assistance and photography guidelines in `ScanGuideSheet` and `home_screen.dart`.
- [x] **Task 2.1**: Implemented `flutter_local_notifications` and `ReminderDialog` for scheduled Morning/Afternoon/Night dosage alarms.
- [x] **Task 2.2**: Built Multi-Medicine Drug Interaction Checker screen (`interaction_checker_screen.dart`) powered by Gemini Vision.
- [x] **Task 2.3**: Built virtual Medicine Cabinet local offline storage & search via `history_screen.dart` and `HistoryService`.
- [x] **Task 3.1**: Built offline safe sample simulation & cached history fallback for when internet is unavailable.
- [x] **Task 3.2**: Added 1-tap Sri Lankan emergency contact dialers (National Poisons Centre, 1990 Suwa Seriya, and nearby pharmacies) via `emergency_directory_screen.dart`.
- [x] **Task 4.1**: Configured encrypted local storage for Gemini API keys with instant runtime override via `api_key_service.dart`.
- [x] **Task 4.2**: Added first-launch Medical Terms & Legal Disclaimer onboarding sheet via `medical_terms_onboarding_modal.dart`.
