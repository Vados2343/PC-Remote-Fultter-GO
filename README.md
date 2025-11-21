# PC Remote Control

 

<p align="center">

  <img src="https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge" alt="Version"/>

  <img src="https://img.shields.io/badge/Go-1.21+-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Go"/>

  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>

  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>

  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows"/>

  <img src="https://img.shields.io/badge/Mobile-Android%20%7C%20iOS-green?style=for-the-badge" alt="Mobile"/>

</p>
 

---

 

## Description

 

**PC Remote Control** - Remote PC power management application that allows you to shutdown or reboot your computer from your smartphone. The server runs on Windows (Go + Fyne GUI), and the mobile client is built with Flutter.


 

---
 

## ✨ Key Features

| Feature | Description |
| :---: | :--- |
| **<p align="center">🔌 Remote Shutdown</p>** | Turn off your PC from anywhere on your local network. |
| **<p align="center">🔄 Remote Reboot</p>** | Restart your PC remotely. |
| **<p align="center">⏳ Timer Shutdown</p>** | Schedule shutdown with a custom timer (10, 30, 60, 120 min or custom). |
| **<p align="center">🔍 Auto-Discovery</p>** | Automatic server discovery via UDP broadcast. |
| **<p align="center">🔒 Secure Connection</p>** | Secret key authentication for all commands. |
| **<p align="center">🌍 Multi-Language</p>** | Supports: English, Русский, Українська, Italiano. |
| **<p align="center">🎨 Theme Support</p>** | Dark and Light UI themes. |
| **<p align="center">💻 System Tray</p>** | Server runs in the background with a system tray icon. |
| **<p align="center">🚀 Auto-Start</p>** | Optional Windows startup integration. |
| **<p align="center">🔑 Remember Me</p>** | Save credentials on the mobile device. |

 

---

 

## Architecture

 

```

┌─────────────────┐         HTTP/REST         ┌─────────────────┐
│                 │  ◄──────────────────────► │                 │
│   Flutter App   │         Port 8080         │   Go Server     │
│   (Mobile)      │                           │   (Windows PC)  │
│                 │  ◄─────────────────────── │                 │
└─────────────────┘      UDP Broadcast        └─────────────────┘

                          Port 5000

```

 

---

 

## Screenshots

 

### Mobile App (Flutter)

 

<p align="center">
    <div style="display: flex; justify-content: center; gap: 10px;">
        <img src="https://github.com/user-attachments/assets/5fe02399-a686-41fa-bbfa-da22d9fc1436" width="49%" alt="Скриншот 1" style="max-width: 49%; height: auto;">
        <img src="https://github.com/user-attachments/assets/d2531f95-ceea-433b-afac-7ae1deda8434" width="49%" alt="Скриншот 2" style="max-width: 49%; height: auto;">
    </div>
</p>

<p align="center">
    <img src="https://github.com/user-attachments/assets/5687d69f-6379-4c17-87db-4661b61c7df4" width="656" height="1280" alt="Скриншот 3" />
</p>

 

### Desktop Server (Go + Fyne)

 

<p align="center">
    <div style="display: flex; justify-content: center; gap: 10px;">
        <img src="https://github.com/user-attachments/assets/96a70fce-d916-4ee1-a586-abdea38acbce" width="49%" alt="Скриншот ПК 1" style="max-width: 49%; height: auto;">
        <img src="https://github.com/user-attachments/assets/d305e415-56b5-4f87-90c2-593a6cafe06e" width="49%" alt="Скриншот ПК 2" style="max-width: 49%; height: auto;">
    </div>
</p>

 

---

 

## Installation

 

### Server (Windows PC)

 

1. **Prerequisites:**

   - Go 1.21 or higher

   - GCC compiler (for CGO/Fyne)

 

2. **Build:**

   ```bash

   cd pc-remote-server

   go mod tidy

   go build -ldflags "-H windowsgui" -o pc-remote-server.exe

   ```

 

3. **Run:**

   - Launch `pc-remote-server.exe`

   - Copy the secret key shown in the window

   - Optionally enable "Run at Windows startup"

 

### Mobile Client (Android/iOS)

 

1. **Prerequisites:**

   - Flutter SDK 3.0+

   - Android Studio or Xcode

 

2. **Build:**

   ```bash

   cd Flutter

   flutter pub get

   flutter build apk --release    # Android

   flutter build ios --release    # iOS

   ```

 

3. **Install:**

   - Transfer APK to your device and install

   - Or use `flutter install`

 

---

 

## Usage

 

1. **Start the server** on your Windows PC

2. **Note the IP address** and **secret key** displayed in the server window

3. **Open the mobile app** on your phone

4. **Enter the IP address** (e.g., `192.168.1.100:8080`)

5. **Enter the secret key**

6. Tap **CONNECT**

7. Use the buttons to **Shutdown**, **Reboot**, or set a **Timer**

 

---

 
## 💻 API Endpoints

| Endpoint | Method | Parameters | Description |
| :--- | :---: | :---: | :--- |
| `/shutdown` | `GET` | `key` | Immediate shutdown |
| `/reboot` | `GET` | `key` | Immediate reboot |
| `/shutdown` | `GET` | `key`, `time` | Scheduled shutdown (time in seconds) |

 

---

 

## Project Structure

 

```

PC-Remote-Flutter-GO/

├── Flutter/                    # Mobile client
│   ├── lib/
│   │   └── main.dart          # Main app code
│   ├── pubspec.yaml           # Dependencies
│   └── ...
├── pc-remote-server/          # Desktop server
│   ├── main.go                # Server code
│   ├── favicon.png            # App icon
│   └── ...
└── README.md
```

 

---

 

## Security

 

- All commands require authentication with a secret key

- Keys are stored securely in user config directory

- Server only accepts connections from local network

- No data is sent to external servers

 

---

 

## Tech Stack

 

**Server:**

- [Go](https://golang.org/) - Backend language

- [Fyne](https://fyne.io/) - GUI framework

- [golang.org/x/sys](https://pkg.go.dev/golang.org/x/sys) - Windows registry access

 

**Client:**

- [Flutter](https://flutter.dev/) - UI framework

- [Dart](https://dart.dev/) - Programming language

- [http](https://pub.dev/packages/http) - HTTP client

- [shared_preferences](https://pub.dev/packages/shared_preferences) - Local storage

 

---

 

<p align="center">

  <strong>Version 1.0.0</strong>

</p>

 

<p align="center">

  <img src="https://img.shields.io/badge/Developed%20%26%20Engineered%20by-vados2343-blueviolet?style=for-the-badge" alt="Author"/>

</p>
