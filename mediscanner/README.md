# MedScan AI (ඖෂධ ස්කෑනර් AI)

**MedScan AI** is a production-ready, cross-platform mobile application built with **Flutter** and powered by **Google Gemini Multimodal Vision API (`gemini-1.5-flash`)**. It enables users to photograph physical medicine tablets, blister strips, syrup bottles, or ointment tubes and instantly receive structured clinical insights extracted directly from label text, brand names, and active ingredients.

All medical insights are formatted cleanly in **two separate languages**:
- **සිංහල (Sinhala)**: Natural, clinically accurate Sinhala terminology.
- **English**: Professional pharmacological and clinical guidance.

---

## 🌟 Key Features

1. **Multimodal OCR & Pharmacological Intelligence**:
   - Analyzes embossed markings, debossed imprint codes, printed packaging, blister foil text, and bottle tables.
   - Extracts Brand Name, Active Generic Ingredients, Dosage Strength, Manufacturer, Clinical Indications, Dosage Instructions, Side Effects, Precautions & Contraindications, and Storage Guidelines.
   - Label clarity detection: warns the user if batch numbers, expiry dates, or strengths appear blurry or worn off.

2. **Material 3 Dual-Tab Interface**:
   - **Tab 1: සිංහල (Sinhala)**
   - **Tab 2: English**
   - High-contrast, clean typography powered by `GoogleFonts.notoSansSinhala` and `GoogleFonts.plusJakartaSans`.
   - Dedicated cards with distinct color accents for each medical data point.

3. **Prominent Medical Disclaimer**:
   - Prominent, visible safety banner reminding users that the AI serves as an informational tool and cannot replace a doctor or pharmacist consultation.

4. **Optimized Camera & Gallery Input**:
   - Image capture via `image_picker` with automatic resizing (`1600x1600`) and quality optimization (`85%`) to maximize OCR clarity while remaining well within Gemini Vision payload limits.

5. **In-App Gemini API Key Manager**:
   - Secure storage in `SharedPreferences`.
   - 1-tap test & setup with direct guidance to [Google AI Studio](https://aistudio.google.com).

6. **Local Scan History**:
   - Automatically saves previous scans locally so users can re-read or search past medications offline.
   - Share reports directly via `share_plus` or copy to clipboard.

7. **One-Tap Demo Sample**:
   - Includes full demonstration sample data (e.g., Panadol Extra blister pack) for immediate testing without taking a photo.

---

## 📁 Project Architecture

```
lib/
├── main.dart                               # Application entry point with Material 3 theming
├── models/
│   └── medicine_analysis_result.dart       # Bilingual data models (MedicineAnalysisResult & MedicineLanguageData)
├── services/
│   ├── api_key_service.dart                # Persistent API key manager using SharedPreferences
│   ├── gemini_service.dart                 # Gemini Vision multimodal communication (gemini-1.5-flash)
│   └── history_service.dart                # Local storage history management
├── theme/
│   └── app_theme.dart                      # Clinical teal palette, typography, and light/dark theme
├── widgets/
│   ├── api_key_modal.dart                  # Bottom sheet for setting up Gemini API key
│   ├── medical_disclaimer_banner.dart      # Visible medical disclaimer banner in Sinhala & English
│   ├── medicine_detail_card.dart           # Reusable data card with copy button & icon accents
│   └── scan_guide_sheet.dart               # Best practices guide for lighting and framing
└── screens/
    ├── home_screen.dart                    # Camera viewfinder, sample demo, and capture triggers
    ├── result_screen.dart                  # Material 3 dual-tab (Sinhala/English) results screen
    └── history_screen.dart                 # Searchable past scans list with delete/open support
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.13+ or 3.24+)
- A free Gemini API key from [Google AI Studio](https://aistudio.google.com)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Run on an Android device or emulator
flutter run -d android

# Or run on iOS Simulator
flutter run -d ios

# Or pass the API key at compile time:
flutter run --dart-define=GEMINI_API_KEY="YOUR_API_KEY"
```

---

## 🔒 Permissions Configured

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.INTERNET`
- `android.permission.CAMERA`
- `android.permission.READ_EXTERNAL_STORAGE`
- `android.permission.READ_MEDIA_IMAGES`

### iOS (`ios/Runner/Info.plist`)
- `NSCameraUsageDescription`: Access to photograph medicine packaging for AI-assisted recognition.
- `NSPhotoLibraryUsageDescription`: Access to select existing medicine photos for AI analysis.
