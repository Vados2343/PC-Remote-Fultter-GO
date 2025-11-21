# PC Remote Control

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/Go-1.21+-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Go"/>
  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows"/>
  <img src="https://img.shields.io/badge/Mobile-Android%20%7C%20iOS-green?style=for-the-badge" alt="Mobile"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/Status-Active-success?style=flat-square" alt="Status"/>
  <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square" alt="PRs Welcome"/>
</p>

---

## Description

**PC Remote Control** - Remote PC power management application that allows you to shutdown or reboot your computer from your smartphone. The server runs on Windows (Go + Fyne GUI), and the mobile client is built with Flutter.

**PC Remote Control** - Приложение для удалённого управления питанием ПК, позволяющее выключать или перезагружать компьютер с телефона. Сервер работает на Windows (Go + Fyne GUI), мобильный клиент создан на Flutter.

---

## Features

| Feature | Description |
|---------|-------------|
| **Remote Shutdown** | Turn off your PC from anywhere on your local network |
| **Remote Reboot** | Restart your PC remotely |
| **Timer Shutdown** | Schedule shutdown with custom timer (10, 30, 60, 120 min or custom) |
| **Auto-Discovery** | Automatic server discovery via UDP broadcast |
| **Secure Connection** | Secret key authentication for all commands |
| **Multi-Language** | English, Русский, Українська, Italiano |
| **Theme Support** | Dark and Light themes |
| **System Tray** | Server runs in background with system tray icon |
| **Auto-Start** | Optional Windows startup integration |
| **Remember Me** | Save credentials on mobile device |

---

## Architecture

```
┌─────────────────┐         HTTP/REST         ┌─────────────────┐
│                 │  ◄───────────────────────► │                 │
│   Flutter App   │         Port 8080         │   Go Server     │
│   (Mobile)      │                           │   (Windows PC)  │
│                 │  ◄───────────────────────  │                 │
└─────────────────┘      UDP Broadcast        └─────────────────┘
                          Port 5000
```

---

## Screenshots

### Mobile App (Flutter)

<p align="center">
  <!-- INSERT MOBILE SCREENSHOTS HERE -->
  <em>[ Mobile App Screenshot 1 ]</em>
</p>

<p align="center">
  <!-- INSERT MOBILE SCREENSHOTS HERE -->
  <em>[ Mobile App Screenshot 2 ]</em>
</p>

### Desktop Server (Go + Fyne)

<p align="center">
  <!-- INSERT PC SCREENSHOTS HERE -->
  <em>[ PC Server Screenshot 1 ]</em>
</p>

<p align="center">
  <!-- INSERT PC SCREENSHOTS HERE -->
  <em>[ PC Server Screenshot 2 ]</em>
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

## API Endpoints

| Endpoint | Method | Parameters | Description |
|----------|--------|------------|-------------|
| `/shutdown` | GET | `key` | Immediate shutdown |
| `/reboot` | GET | `key` | Immediate reboot |
| `/shutdown` | GET | `key`, `time` | Scheduled shutdown (time in seconds) |

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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Version 1.0.0</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Developed%20%26%20Engineered%20by-vados2343-blueviolet?style=for-the-badge" alt="Author"/>
</p>

<p align="center">
  Made with :heart: by <a href="https://github.com/vados2343">vados2343</a>
</p>
