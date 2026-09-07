# Cívica Pago Mobile & Desktop (`apps/mobile`)

Aplicación cliente multiplataforma desarrollada en **Flutter** para el sistema de recaudos y gestión de cartera **Cívica Pago**. Soporta dispositivos móviles (**Android**, **iOS**) y escritorio (**Linux Desktop**, **Windows**).

---

## 🛠️ Requisitos del Sistema y Dependencias Nativas

### 1. Entorno Base
- **Flutter SDK**: `^3.47.2` (Dart `^3.13.2`) gestionado preferentemente con `mise`.
- **Java**: Temurin OpenJDK 17 (para compilación Android).

### 2. Linux Desktop (C++ / GTK Toolchain)
Para compilar y ejecutar la versión nativa de escritorio en Linux (`flutter run -d linux`), se requieren las herramientas de compilación de C++ y librerías del sistema:

#### En Arch Linux / CachyOS:
```bash
sudo pacman -S cmake ninja clang gtk3 pkgconf libsecret
```

#### En Ubuntu / Debian:
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev
```

#### En Fedora:
```bash
sudo dnf install -y clang cmake ninja-build pkgconf-pkg-config gtk3-devel libsecret-devel
```

---

## 🚀 Ejecución en Desarrollo

### 📱 Android (Emulador o Dispositivo Físico)
```bash
cd apps/mobile
flutter run -d android
```

### 🖥️ Linux Desktop (Recomendado para pruebas en escritorio)
```bash
cd apps/mobile
flutter run -d linux
```

### 🌐 Web (Google Chrome)
> [!NOTE]
> La base de datos local SQLite (`drift/native.dart`) opera con FFI nativo C++ en Android, iOS, Linux y Windows. Para pruebas en navegador Chrome:
```bash
cd apps/mobile
export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
flutter run -d chrome
```

---

## 🧪 Pruebas y Control de Calidad

```bash
cd apps/mobile

# Análisis estático de código (0 warnings permitidos)
flutter analyze

# Ejecución de la suite completa de pruebas unitarias y de widgets
flutter test
```
