# 🚀 Guía de Testing con ngrok en Tablet Android

Esta guía te ayudará a probar la app HG Track en una tablet Android usando ngrok para exponer el backend local.

---

## 📋 Requisitos Previos

- **Backend corriendo** en `localhost:8080`
- **Tablet Android** con cable USB
- **Windows** sin WSL
- **Flutter SDK** instalado
- **ADB** configurado (viene con Flutter)

---

## 🔧 PASO 1: Instalar y Configurar ngrok

### 1.1 Descargar ngrok

1. Ir a https://ngrok.com/download
2. Descargar **Windows (64-bit)**
3. Extraer `ngrok.exe` a una carpeta (ej: `C:\ngrok\`)

### 1.2 Crear cuenta y autenticar (RECOMENDADO)

1. Crear cuenta gratuita: https://dashboard.ngrok.com/signup
2. Copiar tu **authtoken** del dashboard
3. Abrir **CMD** o **PowerShell** y ejecutar:

```cmd
cd C:\ngrok
ngrok config add-authtoken TU_TOKEN_AQUI
```

**Beneficios de crear cuenta:**
- URLs más estables (duran horas en lugar de minutos)
- Más conexiones simultáneas
- Sin límite de túneles

### 1.3 Iniciar túnel ngrok

```cmd
cd C:\ngrok
ngrok http 8080
```

**Importante:** Mantén esta ventana abierta mientras pruebas la app.

**Resultado esperado:**
```
ngrok

Session Status                online
Account                       tu_email@example.com
Version                       3.x.x
Region                        United States (us)
Latency                       45ms
Web Interface                 http://127.0.0.1:4040
Forwarding                    https://abc123.ngrok-free.app -> http://localhost:8080

Connections                   ttl     opn     rt1     rt5     p50     p90
                              0       0       0.00    0.00    0.00    0.00
```

**📝 ANOTAR:** La URL HTTPS (ej: `https://abc123.ngrok-free.app`) - la necesitarás en el siguiente paso.

---

## ⚙️ PASO 2: Configurar URL del Backend

### 2.1 Editar archivo `.env`

Abrir el archivo `.env` en la raíz del proyecto y reemplazar:

```env
# ANTES (localhost)
API_BASE_URL=http://localhost:8080/hgapi

# DESPUÉS (ngrok) - Reemplazar con TU URL
API_BASE_URL=https://abc123.ngrok-free.app/hgapi
```

**⚠️ Importante:** 
- Usar la URL **HTTPS** (no HTTP)
- Mantener el sufijo `/hgapi` al final
- La URL cambia cada vez que reinicias ngrok (cuenta gratuita)

### 2.2 Verificar configuración

```bash
# Ver archivo .env
cat .env
```

---

## 📦 PASO 3: Compilar APK para Tablet

### 3.1 Instalar dependencias

```bash
flutter pub get
```

### 3.2 Limpiar build anterior (opcional pero recomendado)

```bash
flutter clean
```

### 3.3 Compilar APK en modo debug

```bash
flutter build apk --debug
```

**Ubicación del APK:**
```
build/app/outputs/flutter-apk/app-debug.apk
```

**Tiempo estimado:** 2-5 minutos (primera vez puede tardar más)

---

## 📱 PASO 4: Instalar en Tablet vía USB + ADB

### 4.1 Habilitar depuración USB en tablet

1. Ir a **Ajustes** > **Acerca del dispositivo**
2. Tocar **Número de compilación** 7 veces (aparecerá "Eres desarrollador")
3. Volver a **Ajustes** > **Sistema** > **Opciones de desarrollador**
4. Activar **Depuración USB**

### 4.2 Conectar tablet por USB

1. Conectar cable USB entre PC y tablet
2. En tablet, aparecerá diálogo "¿Permitir depuración USB?"
3. Marcar "Permitir siempre desde este equipo" y tocar **OK**

### 4.3 Verificar conexión ADB

```bash
adb devices
```

**Resultado esperado:**
```
List of devices attached
ABC123XYZ       device
```

Si aparece `unauthorized`, repetir paso 4.2.

### 4.4 Instalar APK

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Reinstalar (si ya existe):**
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Resultado esperado:**
```
Performing Streamed Install
Success
```

---

## 🧪 PASO 5: Testing y Validación

### 5.1 Ejecutar app en tablet

1. Buscar app **HG Control Tiempo OT** en la tablet
2. Abrir la app

### 5.2 Monitorear logs en tiempo real

**En PC (nueva terminal):**
```bash
adb logcat | findstr "flutter"
```

**En ngrok (consola donde corre ngrok):**
Verás todas las peticiones HTTP entrantes:
```
GET /hgapi/listarempleadosconactividades   200 OK
POST /hgapi/consultaractividadesempleado   200 OK
```

### 5.3 Checklist de pruebas

- [ ] **Login:** App carga lista de empleados
- [ ] **Selección:** Tocar empleado muestra sus actividades pendientes
- [ ] **Iniciar:** Tocar actividad y presionar "Iniciar"
- [ ] **Pausar:** Presionar "Pausar" mientras actividad está en curso
- [ ] **Reanudar:** Presionar "Reanudar" desde estado pausado
- [ ] **Finalizar:** Presionar "Finalizar" y verificar que actividad desaparece
- [ ] **Persistencia:** Cerrar/abrir app con actividad en curso (debe restaurar estado)
- [ ] **Backend:** Verificar en backend que los datos se guardaron correctamente

### 5.4 Verificar peticiones en ngrok Web UI

Abrir en navegador: http://localhost:4040

Aquí puedes ver:
- Todas las peticiones HTTP
- Headers de request/response
- Body JSON de cada petición
- Tiempos de respuesta

---

## 🔄 PASO 6: Workflow de Desarrollo

### Escenario A: Desarrollo en PC (Chrome/Windows)

```env
# .env
API_BASE_URL=http://localhost:8080/hgapi
```

```bash
flutter run -d chrome
# o
flutter run -d windows
```

### Escenario B: Testing en Tablet

```env
# .env
API_BASE_URL=https://abc123.ngrok-free.app/hgapi
```

```bash
# Terminal 1: Iniciar ngrok (dejar corriendo)
cd C:\ngrok
ngrok http 8080

# Terminal 2: Compilar y desplegar
flutter clean
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Terminal 3 (opcional): Ver logs
adb logcat | findstr "flutter"
```

---

## 🚨 Troubleshooting

### Problema: "Unable to load asset .env"

**Causa:** El archivo `.env` no está incluido en el bundle.

**Solución:**
```yaml
# En pubspec.yaml, verificar:
flutter:
  assets:
    - .env
```

Luego recompilar:
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

---

### Problema: "Error de conexión" en tablet

**Causa:** Backend no accesible o URL incorrecta.

**Verificar:**
1. ngrok está corriendo (`ngrok http 8080`)
2. URL en `.env` es correcta (copiar desde ngrok)
3. URL tiene el prefijo `https://` y sufijo `/hgapi`

**Probar URL manualmente:**
```bash
curl https://abc123.ngrok-free.app/hgapi/listarempleadosconactividades
```

---

### Problema: ngrok muestra pantalla de advertencia

**Causa:** Con cuenta gratuita, la primera petición muestra advertencia "ngrok Free".

**Soluciones:**
- Opción 1 (gratis): Refrescar/reintentar en la app
- Opción 2 (pago): Obtener dominio fijo con plan de pago ($8/mes)

---

### Problema: "device unauthorized" en ADB

**Causa:** Tablet no autorizó depuración USB.

**Solución:**
1. Desconectar USB
2. En tablet: Desactivar y reactivar "Depuración USB"
3. Reconectar USB
4. Aceptar diálogo de autorización en tablet

---

### Problema: App se cierra inesperadamente

**Ver logs detallados:**
```bash
adb logcat
```

Buscar líneas con `flutter`, `Exception`, o `Error`.

---

### Problema: URL de ngrok cambia constantemente

**Causa:** Cuenta gratuita regenera URL cada vez que se reinicia ngrok.

**Soluciones:**
- No cerrar ngrok mientras trabajas
- Actualizar `.env` si reinicias ngrok
- Opción: Pagar plan ngrok para URL fija

---

## 📊 Comandos Útiles de Referencia

```bash
# Ver dispositivos Android conectados
adb devices

# Instalar APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Reinstalar APK (sobrescribe)
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Ver logs en tiempo real
adb logcat | findstr "flutter"

# Limpiar logs
adb logcat -c

# Desinstalar app
adb uninstall com.hagemsa.hgtrack

# Iniciar ngrok
ngrok http 8080

# Iniciar ngrok con subdominio fijo (requiere plan pago)
ngrok http 8080 --domain=mi-subdominio.ngrok-free.app

# Ver versión de Flutter
flutter --version

# Listar dispositivos disponibles
flutter devices

# Compilar APK debug
flutter build apk --debug

# Compilar APK release (producción)
flutter build apk --release

# Limpiar cache de build
flutter clean

# Obtener dependencias
flutter pub get

# Analizar código
flutter analyze
```

---

## 🔒 Consideraciones de Seguridad

⚠️ **Importante:**

1. **ngrok expone tu backend a internet** - Solo usar para desarrollo/testing
2. **No dejar ngrok corriendo 24/7** - Cerrar cuando termines de probar
3. **No commitear archivo `.env`** - Ya está en `.gitignore`
4. **URLs de ngrok son temporales** - No compartirlas en documentación permanente
5. **No usar ngrok en producción** - Solo para desarrollo

---

## 📈 Próximos Pasos

Después de probar exitosamente:

1. **Revertir `.env` a localhost**
   ```env
   API_BASE_URL=http://localhost:8080/hgapi
   ```

2. **Cerrar ngrok**
   ```
   Ctrl+C en la terminal de ngrok
   ```

3. **Continuar desarrollo normal en PC**
   ```bash
   flutter run -d chrome
   ```

---

## 💡 Tips y Mejores Prácticas

### Optimizar velocidad de compilación

```bash
# Compilar solo para arquitectura de tu tablet (más rápido)
flutter build apk --debug --target-platform android-arm64
```

### Hot Reload en tablet (requiere conexión ADB)

```bash
flutter run -d "nombre-tablet"
# Ahora puedes usar 'r' para hot reload
```

**Para obtener nombre del dispositivo:**
```bash
flutter devices
```

### Ver interfaz web de ngrok

Abrir en navegador: http://localhost:4040

Útil para:
- Ver historial de peticiones
- Inspeccionar payloads JSON
- Depurar errores de API
- Medir tiempos de respuesta

---

## 📞 Soporte

Si encuentras problemas no cubiertos en esta guía:

1. Verificar logs: `adb logcat | findstr "flutter"`
2. Verificar peticiones en ngrok: http://localhost:4040
3. Verificar estado del backend: `curl http://localhost:8080/hgapi`
4. Verificar configuración: `cat .env`

---

**¡Listo para probar! 🎉**

Recuerda: ngrok debe estar corriendo en una terminal mientras pruebas la app en la tablet.
