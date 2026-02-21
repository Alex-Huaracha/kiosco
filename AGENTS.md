# HG Track - Agent Development Guide

## Project Overview
**HG Track** is a Flutter mobile/tablet application for tracking maintenance work orders (Órdenes de Trabajo) in industrial environments. The app is optimized for tablets used by maintenance technicians in outdoor/field conditions.

**Target Platforms:** Android tablets (primary), Web (development), Windows (development)  
**Main User:** Maintenance technicians working on vehicles and equipment

---

## 🧭 Navigation Architecture

### Current Flow (Simplified - No OT Grouping)
```
1. EmpleadosListPage (Login)
   ↓ Select employee
2. ActividadesPendientesEmpleadoPage (Activity List)
   ↓ Tap on activity card
3. ActividadDetallePage (Time Tracking)
   ↓ Start/Pause/Resume/Finish
   Backend (TODO: finalizaractividadempleado endpoint)
```

### Key Design Decisions
- **No OT grouping:** Each technician has ~10 tasks/day max, making grouping unnecessary
- **Flat list:** All pending activities shown in a single scrollable grid
- **Direct access:** Tap activity card → go directly to detail/tracking screen
- **Backlog support:** Activities from closed OTs are shown at the end (orange badge)

### Screen Responsibilities

| Screen | Purpose | Key Actions |
|--------|---------|-------------|
| `EmpleadosListPage` | Employee selection (no auth) | Select employee → Navigate |
| `ActividadesPendientesEmpleadoPage` | View all pending activities | Load activities, filter, sort, navigate to detail |
| `ActividadDetallePage` | Track time on single activity | Start, Pause, Resume, Finish, Add notes |

---

## 🚀 Build, Run & Test Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run on different platforms
flutter run -d chrome              # Web (fastest for development)
flutter run -d windows             # Windows desktop
flutter run -d "device-name"       # Android tablet (e.g., "Lenovo TB X306X")

# Hot reload (while running)
r                                  # Hot reload
R                                  # Hot restart
q                                  # Quit

# Clean build artifacts
flutter clean
flutter pub get
```

### Code Quality
```bash
# Analyze code (lint checks)
flutter analyze

# Format code
dart format lib/

# Check for outdated packages
flutter pub outdated
```

### Building for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web --release
```

### Android-Specific Commands
```bash
# Stop Gradle daemons (if build issues occur)
cd android && ./gradlew --stop && cd ..

# Clean Gradle cache
cd android && ./gradlew clean && cd ..

# View connected devices
flutter devices
```

---

## 📁 Project Structure

```
lib/
├── main.dart                                      # App entry point with theme
├── utils/
│   └── app_colors.dart                           # WCAG AAA color palette
├── login/view/
│   └── empleados_list_page.dart                  # Employee selection screen
└── appseguimiento/
    ├── model/
    │   ├── actividad_tracking_state.dart         # ⭐ Time tracking state machine
    │   ├── actividad_empleado_model.dart         # Activity DTO
    │   ├── hgempleadomantenimiento_model.dart    # Employee DTO
    │   ├── hgdetalleordentrabajodto_model.dart   # Activity detail DTO
    │   └── hgordentrabajodto_model.dart          # Work order DTO
    ├── service/
    │   ├── actividad_local_storage_service.dart  # ⭐ SharedPreferences persistence
    │   ├── tracking_service_actividades_empleado.dart
    │   ├── tracking_service_empleado_mantenimiento.dart
    │   └── tracking_service_ordentrabajo.dart
    ├── provider/
    │   └── tracking_api.dart                     # HTTP client
    └── views/
        ├── actividades_pendientes_empleado_page.dart  # ⭐ Activity list (main screen)
        └── actividad_detalle_page.dart                # ⭐ Time tracking detail
```

**⭐ = Core files for time tracking feature**

---

## 🎨 Code Style Guidelines

### Imports
```dart
// Order: dart, flutter, packages, relative
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:hgtrack/utils/app_colors.dart';
import 'package:hgtrack/appseguimiento/model/example_model.dart';
```

### Naming Conventions
- **Files:** `snake_case.dart` (e.g., `empleados_list_page.dart`)
- **Classes:** `PascalCase` (e.g., `EmpleadosListPage`, `TrackingApi`)
- **Variables/Functions:** `camelCase` (e.g., `loadEmpleados`, `empleadosList`)
- **Constants:** `camelCase` with `static const` (e.g., `AppColors.primary`)
- **Private members:** `_leadingUnderscore` (e.g., `_calculateAspectRatio`)

### Widget Structure
```dart
class MyWidget extends StatelessWidget {
  final String requiredParam;
  final int? optionalParam;

  const MyWidget({
    super.key,
    required this.requiredParam,
    this.optionalParam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Widget tree
    );
  }
}
```

### State Management
- Use **Provider** for global state (`MyAppState` in `main.dart`)
- Use **StatefulWidget** for local component state
- Keep state minimal and close to where it's used

---

## 🎨 Design System

### Colors (AppColors in `utils/app_colors.dart`)
**IMPORTANT:** Always use `AppColors` constants, never hardcoded colors.

```dart
// Primary colors (Blue Industrial - outdoor optimized)
AppColors.primary          // #1565C0 - Main blue
AppColors.primaryDark      // #0D47A1 - Hover/pressed states
AppColors.accent           // #0277BD - Accent elements

// Text colors
AppColors.textPrimary      // #212121 - Main text
AppColors.textSecondary    // #757575 - Secondary text
AppColors.textOnPrimary    // White - Text on blue backgrounds

// Background colors
AppColors.background       // #F5F5F5 - Screen background
AppColors.cardBackground   // White - Card backgrounds
AppColors.bannerBackground // #E3F2FD - Info banners

// State colors
AppColors.error            // #D32F2F - Errors only
AppColors.success          // #2E7D32 - Success states
AppColors.warning          // #F57C00 - Warnings

// Legacy (use sparingly)
AppColors.hgRed            // #E02E30 - Only for logo/branding
```

### Typography
```dart
// Headings
fontSize: 22, fontWeight: FontWeight.bold  // Page titles
fontSize: 20, fontWeight: FontWeight.bold  // Section headers
fontSize: 18, fontWeight: FontWeight.bold  // Card titles

// Body text
fontSize: 16, fontWeight: FontWeight.normal  // Standard body
fontSize: 15, fontWeight: FontWeight.w500    // Secondary info
fontSize: 14, fontWeight: FontWeight.normal  // Tertiary info
```

### Spacing
```dart
const SizedBox(height: 16)  // Standard vertical spacing
const SizedBox(height: 12)  // Compact vertical spacing
const SizedBox(height: 8)   // Tight vertical spacing
const SizedBox(width: 16)   // Standard horizontal spacing
const SizedBox(width: 12)   // Compact horizontal spacing

const EdgeInsets.all(16)              // Card padding
const EdgeInsets.symmetric(h: 16, v: 8)  // Compact padding
```

### Responsive Design
```dart
// Use MediaQuery for breakpoints
final width = MediaQuery.of(context).size.width;
final columns = width < 800 ? 2 : 3;  // 2 cols portrait, 3 cols landscape

// Aspect ratios for GridView
final aspectRatio = width < 800 ? 1.8 : 1.6;  // Cards more horizontal in landscape
```

### Activity Card Design (ActividadesPendientesEmpleadoPage)

**Visual Structure:**
```
┌─────────────────────────────────────────────┐
│ 🚛 ABC-123 • OT-456       [En Proceso]     │ ← Mini-header with badge
├─────────────────────────────────────────────┤
│ Cambio de aceite (backlog) 📅 03/02/2026  │ ← Title + "(backlog)" if bbacklog=true
│ ⏱ 2h 30min                                 │
│ 📁 Sistema Motor                            │
│ 🕐 Inicio: 8:30 AM                     →   │
└─────────────────────────────────────────────┘
```

**Badge Colors:**
- 🔵 `AppColors.primary` (Blue) - "En Proceso" (activity started)
- ⚪ `AppColors.textSecondary` (Gray) - "No Iniciada" (not started)

**Date Color Indicators:**
- 🔵 `AppColors.primary` - Today or yesterday
- 🟠 `AppColors.warning` - More than 1 day old

**Backlog Handling:**
- Backlog activities are **NOT separated** into a different section
- Backlog is indicated by adding **(backlog)** text after the activity title
- Backlog activities are mixed with normal activities in the same list

**Sorting Logic:**
1. Activities "En Proceso" first (with local tracking or started in BD)
2. Activities "No Iniciada" second
3. By registration date (most recent first)
Note: Backlog activities are sorted alongside normal activities, no special ordering

---

## 🔌 API Integration Patterns

### HTTP Requests (in `tracking_api.dart`)
```dart
Future<List<ModelDto>?> getDataFromApi() async {
  var client = http.Client();
  var url = 'https://api.example.com/endpoint';
  var uri = Uri.parse(url);

  String jsonBody = jsonEncode({
    "param1": value1,
    "param2": null,  // Null values are acceptable
  });

  try {
    var response = await client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonBody,
    );

    if (response.statusCode == 200) {
      if (response.body == "[]" || response.body.isEmpty) {
        return null;
      }
      return modelDtoFromJson(
        const Utf8Decoder().convert(response.bodyBytes)
      );
    } else {
      print("Error: HTTP ${response.statusCode}");
    }
  } catch (e) {
    print("Exception: $e");
  }
  return null;
}
```

### Error Handling
- Return `null` for empty/error responses
- Use `try-catch` blocks for all API calls
- Print errors for debugging (use `print()` not `debugPrint()`)
- Show user-friendly messages with `SnackBar` or error states

---

## 📱 UI Patterns

### Loading States
```dart
if (isLoading) {
  return const Center(
    child: CircularProgressIndicator(color: AppColors.primary),
  );
}
```

### Error States
```dart
if (errorMessage != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text(errorMessage!, textAlign: TextAlign.center),
        ElevatedButton(onPressed: retry, child: Text('Reintentar')),
      ],
    ),
  );
}
```

### GridView for Lists (Tablets)
```dart
GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: _calculateColumns(context),
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: _calculateAspectRatio(context),
  ),
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(item: items[index]),
)
```

---

## ⏱️ Time Tracking System

### State Machine (ActividadTrackingState)

```dart
enum EstadoActividad {
  noIniciada,    // Initial state
  enProceso,     // Currently working
  pausada,       // Temporarily paused
  finalizada     // Completed (terminal state)
}
```

**State Transitions:**
```
NoIniciada → EnProceso (iniciar)
EnProceso → Pausada (pausar)
Pausada → EnProceso (reanudar)
EnProceso → Finalizada (finalizar)
Pausada → Finalizada (finalizar desde pausa)
```

### Time Tracking Logic

**Periods Model:**
```dart
class PeriodoTrabajo {
  final DateTime inicio;
  final DateTime? fin;
  Duration? get duracion => fin?.difference(inicio);
}
```

**Time Calculation:**
- **Total Worked Time** = Sum of all closed periods + current active period (if in progress)
- **Total Pause Time** = Sum of gaps between consecutive periods
- **Current Period** = `DateTime.now() - inicioActual` (only when in progress)

**Validations:**
```dart
// Minimum pause duration: 5 seconds
const minPauseDuration = Duration(seconds: 5);

// Minimum work time before finalizing: 1 minute
const minWorkDuration = Duration(minutes: 1);
```

### Persistence (ActividadLocalStorageService)

**Storage Key Format:**
```
actividad_tracking_{actividadId}
```

**Methods:**
```dart
Future<void> saveState(ActividadTrackingState state);
Future<ActividadTrackingState?> loadState(int actividadId);
Future<void> clearState(int actividadId);
Future<List<int>> getAllTrackedActividades();
```

**Data Flow:**
1. User actions (Start/Pause/Resume) → Update state → Auto-save to SharedPreferences
2. On page load → Load from SharedPreferences → Restore UI state
3. On finalize → Send to backend → Clear local storage

### Responsive Layout (ActividadDetallePage)

**Portrait Mode (width ≤ 800px):**
```
┌─────────────────┐
│ Info OT         │
│ Info Actividad  │
│ Estado Actual   │
│ Acciones        │
│ Observaciones   │
│ Historial       │
└─────────────────┘
```

**Landscape Mode (width > 800px):**
```
┌──────────────────┬──────────┐
│ Info OT (60%)    │ Estado   │
│ Info Actividad   │ Actual   │
│ Observaciones    │ (40%)    │
│                  │ Acciones │
│                  │ Historial│
└──────────────────┴──────────┘
```

### Timeline Component

**Visual Format:**
```
🟢 Iniciada - 08:00 AM
⏸️ Pausada - 10:30 AM (2h 30min trabajados)
▶️ Reanudada - 10:45 AM (15min en pausa)
🏁 Finalizada - 01:00 PM (2h 45min trabajados)
```

**Color Coding:**
- 🟢 Green - Started
- 🟠 Orange - Paused
- 🔵 Blue - Resumed
- 🏁 Gray - Finished

---

## ⚠️ Common Pitfalls to Avoid

1. **Never hardcode colors** - Always use `AppColors` constants
2. **Never use `.withOpacity()`** - Use `.withAlpha()` instead (not deprecated)
3. **Always handle null** - Use `??` operators and null checks
4. **Keep widgets small** - Extract to separate widgets if > 100 lines
5. **Use const constructors** - Add `const` wherever possible for performance
6. **Test on tablet size** - Default to tablet viewport (800-1200px width)
7. **Avoid nested Columns/Rows** - Use `Flex` or refactor to smaller widgets

---

## 🐛 Debugging Tips

```bash
# View detailed logs
flutter run --verbose

# View device logs (Android)
adb logcat | grep flutter

# Profile performance
flutter run --profile
```

---

## 📚 Key Dependencies

- `provider: ^6.1.2` - State management
- `http: ^1.2.1` - HTTP requests
- `shared_preferences: ^2.2.2` - Local persistence for time tracking
- `pdf: ^3.11.3` - PDF generation
- `signature: ^5.5.0` - Digital signatures
- `printing: ^5.14.2` - Print functionality

---

## 🎯 Project-Specific Notes

- **Target user:** Maintenance technicians (male, outdoor work environment)
- **Accessibility:** WCAG AAA compliant colors for outdoor visibility
- **No authentication:** Employees select themselves from a list (internal network only)
- **Offline-first:** Not implemented yet, but consider for future
- **Tablet-first:** UI designed primarily for 10" Android tablets in landscape mode
- **Local persistence:** Time tracking states saved to SharedPreferences (survives app restart)
- **Backlog handling:** Activities with `bbacklog=true` show "(backlog)" text in title, mixed with normal activities
- **No OT grouping:** Direct flat list of all activities (~10 max per technician)

---

## 🚧 Known TODOs & Pending Work

### ✅ Backend Integration - Endpoints Unificados (COMPLETED)

**Status:** ✅ Fully migrated to unified RESTful endpoints (Feb 2026)

#### Tareas Principales (TP) - DetalleOrdenTrabajo
**Endpoint:** `POST /api/v1/gestionarestadoactividad`

**Implementation:**
- `TrackingApi.gestionarEstadoActividadTP()` - Unified HTTP client for all actions
- `ActivityService.iniciarActividadTP()` - INICIAR wrapper
- `ActivityService.pausarActividadTP()` - PAUSAR wrapper (returns idpausa)
- `ActivityService.reanudarActividadTP()` - REANUDAR wrapper (idpausa is optional)
- `ActivityService.finalizarActividadTPNuevo()` - FINALIZAR wrapper

#### Sub-Tareas (ST) - DetalleAsignacion
**Endpoint:** `POST /api/v1/gestionarestadosubtarea`

**Implementation:**
- `TrackingApi.gestionarEstadoActividadST()` - Unified HTTP client for all actions
- `ActivityService.iniciarActividadST()` - INICIAR wrapper (NEW - supervisors can see when assistant starts)
- `ActivityService.pausarActividadST()` - PAUSAR wrapper (returns idpausa)
- `ActivityService.reanudarActividadST()` - REANUDAR wrapper (idpausa is optional, backend finds active pause)
- `ActivityService.finalizarActividadSTNuevo()` - FINALIZAR wrapper

#### Arquitectura Común

**Acciones soportadas:** INICIAR, PAUSAR, REANUDAR, FINALIZAR

**Máquina de Estados:**
```
NO_INICIADA ──INICIAR──> EN_PROCESO
EN_PROCESO  ──PAUSAR───> PAUSADA
PAUSADA     ──REANUDAR─> EN_PROCESO
EN_PROCESO  ──FINALIZAR> TERMINADA
```

**Date Format:** `yyyy-MM-dd HH:mm:ss.SSS` (custom format, not ISO8601)

**Key Features:**
- ✅ INICIAR sends timestamp to backend immediately (real-time sync for supervisors)
- ✅ PAUSAR creates pause record and returns idpausa (stored locally for debugging)
- ✅ REANUDAR automatically finds active pause (no idpausa needed in 99% of cases)
- ✅ FINALIZAR - backend calculates worked minutes automatically
- ✅ Offline support with automatic queue retry using new format
- ✅ GestionEstadoResponse supports both TP (iddetalleordentrabajo) and ST (iddetalleasignacion)

**Request Example (TP):**
```json
{
  "iddetalleordentrabajo": "354827",
  "accion": "INICIAR",
  "timestamp": "2026-02-21 10:30:00.000"
}
```

**Request Example (ST):**
```json
{
  "iddetalleasignacion": "14",
  "accion": "PAUSAR",
  "timestamp": "2026-02-21 11:00:00.000",
  "idmotivo": "1"
}
```

**Deprecated Endpoints (DO NOT USE):**
- `finalizarAsignacion()` → Use `gestionarEstadoActividadST(accion: "FINALIZAR")`
- `registrarPausaST()` → Use `gestionarEstadoActividadST(accion: "PAUSAR")`
- `reanudarPausaST()` → Use `gestionarEstadoActividadST(accion: "REANUDAR")`

**Features:**
- Automatic retry on network errors (local state preserved)
- Full error handling with user-friendly messages
- Activity disappears from list after successful completion

### Future Enhancements

1. **Offline Sync Queue**
   - Store completed activities when offline
   - Auto-sync when connection restored
   - Conflict resolution strategy

2. **User Experience**
   - Sound/vibration feedback on state changes
   - Push notifications for paused activities (>30min)
   - Daily/weekly time summary dashboard

3. **Testing**
   - Unit tests for `ActividadTrackingState` logic
   - Widget tests for time tracking UI
   - Integration tests on real Android tablets

4. **Performance**
   - Battery impact analysis for time calculations
   - Optimize GridView rendering for large lists
   - Image caching for vehicle photos

### Known Warnings (Non-Critical)

- `onPopInvoked` deprecated → Migrate to `onPopInvokedWithResult` (Flutter 3.22+)
- `analysis_options.yaml` missing `flutter_lints` package (optional)
