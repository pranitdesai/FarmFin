# 🌾 FarmFin

FarmFin is a farm sales and ledger management mobile application built to simplify record keeping for farms and agricultural businesses. It helps farmers and farm owners digitally manage yearly sales, plot-wise production records, merchant/customer transactions, and automatically generated invoices — eliminating the need for manual notebooks and reducing calculation errors.

The app is developed using **Flutter** for a smooth cross-platform experience and uses **Firebase Realtime Database** for secure cloud storage and real-time synchronization of data.

---

## ✨ Features

### 📅 Yearly Sales Ledger
- Organize sales records year-wise for each farming season.
- Easily switch between years for tracking and reporting.

### 🌱 Plot-Wise Tracking
- Add and manage multiple farm plots.
- Maintain sales details separately for each plot.

### 🧑‍💼 Merchant / Customer Management
- Store merchant/customer-wise sales data.
- Allows quick lookup of sales entries and transaction history.

### 🧾 Sales Entries System
Each sales entry supports:
- Quantity
- Box weight
- Total weight
- Rate per unit
- Total amount calculation

### 🧮 Auto Calculations & Summaries
- Automatically calculates total weight and total amount.
- Provides summaries for yearly and merchant-wise records.

### 📄 Dynamic Invoice Generation
- Invoice screen dynamically loads sales ledger data from Firebase.
- Displays records in an organized card/table style UI.
- Useful for printing, sharing, and reporting.

### ☁️ Firebase Integration
- Firebase Realtime Database for structured ledger storage.
- Supports secured access using Firebase Authentication-based rules.

---

## 🛠 Tech Stack

- **Flutter** (Dart)
- **Firebase Realtime Database**
- **Firebase Authentication**
- **Firebase Storage** (if used for supporting documents/media)
- UI Components:
    - Material UI
    - Dynamic CardViews / Table Layout based structure
    - Custom fonts (Poppins)

---

## 📁 Project Structure (Overview)

```txt
lib/
 ├── Screens/
 │    ├── Home/
 │    ├── Ledger/
 │    ├── Invoice/
 │    ├── AddPlot/
 │    └── Authentication/
 ├── Utils/
 │    ├── constants.dart
 │    ├── app_color.dart
 │    └── helpers.dart
 ├── Widgets/
 └── main.dart
