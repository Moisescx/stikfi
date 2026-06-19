#!/bin/bash

echo "Iniciando proceso de compilación automática..."

perl -i -pe 's/version: (\d+\.\d+\.\d+)\+(\d+)/"version: $1+".($2+1)/e' pubspec.yaml

NUEVA_VERSION=$(grep "^version: " pubspec.yaml | awk '{print $2}')
echo "Versión actualizada exitosamente a: $NUEVA_VERSION"

echo "Compilando APK con ofuscación y firma de seguridad..."
flutter build apk --release --obfuscate --split-debug-info=./debug_info --no-tree-shake-icons --split-per-abi

echo "Renombrando el archivo optimizado a stikfi.apk..."
mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk build/app/outputs/flutter-apk/stikfi.apk

echo "¡Compilación terminada!"
echo "Tu APK seguro y optimizado está listo en: build/app/outputs/flutter-apk/stikfi.apk"