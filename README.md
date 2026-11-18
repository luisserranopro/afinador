# Diapasón

**Afinador para guitarra, ukelele y cromático**, hecho en Flutter. Escucha
por el micrófono, detecta la nota con el algoritmo YIN y muestra con una
aguja si la cuerda está grave, aguda o afinada. Todo se analiza en el móvil:
no se graba nada ni se envía a ningún sitio. En español o inglés.

## Qué incluye

- **Guitarra:** estándar, Drop D, medio tono abajo, un tono abajo, DADGAD y
  Open G.
- **Ukelele:** estándar (Sol agudo), Sol grave y barítono.
- **Cromático:** cualquier nota, de unos 60 a 1500 Hz.
- **Cuerda automática o fijada:** detecta qué cuerda tocas; si tocas un botón
  de cuerda, compara siempre con esa (útil si está muy desafinada). Cada
  cuerda se marca con ✓ cuando aguanta afinada medio segundo.
- **Ajustes:** La de referencia de 430 a 450 Hz y nombres de notas
  Do-Re-Mi o C-D-E. Se recuerdan entre sesiones.

## Puesta en marcha

1. Clona el repositorio y entra en la carpeta.
2. Genera las carpetas de cada plataforma:
   ```
   flutter create --org work.alcancia --project-name afinador --platforms android,ios,web .
   ```
   El identificador de la app será `work.alcancia.afinador`.
3. **Permiso del micrófono** (imprescindible):
   - **Android:** en `android/app/src/main/AndroidManifest.xml`, antes de
     `<application`:
     ```xml
     <uses-permission android:name="android.permission.RECORD_AUDIO" />
     ```
     y cambia `android:label="afinador"` por `android:label="Diapasón"`.
   - **iOS:** en `ios/Runner/Info.plist`, dentro de `<dict>`:
     ```xml
     <key>NSMicrophoneUsageDescription</key>
     <string>Para escuchar tu instrumento y afinarlo. No se graba nada.</string>
     ```
   - **Web:** el navegador pide permiso solo. Funciona en `localhost` o con
     `https` (no en `http` normal).
4. Dependencias, iconos y pantalla de arranque:
   ```
   flutter pub get
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
5. Comprueba y prueba **en un móvil de verdad** (el micrófono del emulador
   suele dar problemas):
   ```
   flutter analyze
   flutter test
   flutter run
   ```

## Estructura

```
lib/
  main.dart                     Arranque, tema e idioma
  i18n.dart                     Textos en español e inglés
  audio/
    yin.dart                    Detección de la frecuencia (algoritmo YIN)
    notas.dart                  Notas, cents, afinaciones de cada instrumento
    microfono.dart              Micrófono → muestras → YIN, unas 20 veces/s
  estado/
    afinador.dart               Estado: cuerda, lectura, suavizado, afinadas
    preferencias.dart           Ajustes guardados
  pantallas/afinador_pantalla.dart  Pantalla principal y ajustes
  widgets/aguja.dart            Medidor de aguja (CustomPainter)
test/                           YIN con señales sintéticas, notas y estado
assets/icon/                    Logo en SVG y PNG
store/                          Icono 512 y gráfico 1024×500 para Google Play
docs/                           Política de privacidad
```

## Cómo funciona

1. **Micrófono.** El paquete `record` entrega el audio en crudo (PCM de
   16 bits, 44 100 muestras por segundo). Se guardan las últimas 4096
   muestras (≈ 93 ms) y, cada 2048 nuevas (≈ 46 ms), se analizan.
2. **YIN.** Un sonido afinado se repite cada periodo. Se compara la señal
   consigo misma desplazada τ muestras: cuando τ es el periodo, la diferencia
   es casi cero, y la frecuencia es 44 100 / τ. Se toma el primer mínimo bajo
   un umbral (así no se confunde de octava) y se interpola entre muestras
   para afinar al décimo de hercio.
3. **Notas y cents.** Con La4 = 440 Hz, una nota está a
   `12 · log2(f / 440)` semitonos del La; un cent es 1/100 de semitono.
   ±5 cents se considera afinado.
4. **Suavizado.** Se usa la mediana de las 5 últimas lecturas: elimina saltos
   sueltos (por ejemplo, de octava) con un retraso de apenas unos 90 ms.

Los tests generan señales que imitan una cuerda pulsada (fundamental,
armónicos y ruido) y comprueban que YIN acierta con menos de 2 cents de
error, también cuando el segundo armónico suena más fuerte que la nota.

## Publicar en Google Play

Igual que las otras apps: clave de subida propia (`afinador-upload.jks`),
`android/key.properties`, los tres cambios de firma en
`android/app/build.gradle.kts`, `flutter build appbundle` y comprobar la firma
con `keytool -printcert`. En el cuestionario de seguridad de datos, declara
que la app usa el micrófono pero **no recoge ni comparte** audio: se procesa
en el dispositivo. Imágenes en `store/` y política en `docs/`.
