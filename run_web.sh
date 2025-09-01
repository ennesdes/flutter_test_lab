#!/bin/bash

# Script para rodar Flutter web sem criar múltiplos ícones do Chrome

echo "🔄 Parando instâncias anteriores do Chrome..."
pkill -f "flutter_tools_chrome_device" 2>/dev/null

echo "🧹 Limpando cache..."
flutter clean

echo "📦 Obtendo dependências..."
flutter pub get

echo "🌐 Iniciando Flutter web..."
flutter run -d chrome \
  --web-port=8080 \
  --web-hostname=localhost \
  --web-renderer html \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --release

echo "✅ Flutter web iniciado em http://localhost:8080"
