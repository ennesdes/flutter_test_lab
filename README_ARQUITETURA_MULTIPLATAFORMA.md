# 🏗️ Arquitetura Multiplataforma de Áudio

Este projeto implementa uma arquitetura modular e escalável para funcionalidades de áudio em diferentes plataformas, mantendo uma interface comum e otimizando recursos específicos de cada ambiente.

## 📱 Suporte Multiplataforma

### 🎯 **Mobile (Android/iOS)**
- **Gravação**: `record` package com suporte nativo
- **Reprodução**: `just_audio` com controles avançados
- **Permissões**: `permission_handler` para microfone
- **Armazenamento**: Sistema de arquivos nativo
- **Interface**: Duas opções (compacta e completa)

### 🌐 **Web (Browser)**
- **Gravação**: MediaRecorder API nativa
- **Reprodução**: `just_audio` com suporte web
- **Armazenamento**: localStorage com base64
- **Permissões**: Solicitação automática de microfone
- **Interface**: Padrão web

### 🖥️ **Desktop (Windows/macOS/Linux)**
- **Gravação**: FFmpeg via Process API
- **Reprodução**: `just_audio` multiplataforma
- **Armazenamento**: Sistema de arquivos local
- **Permissões**: Verificação de ferramentas disponíveis
- **Interface**: Padrão desktop

## 🏗️ Estrutura da Arquitetura

```
lib/audio/
├── services/
│   ├── audio_service_interface.dart     # Interface comum
│   ├── audio_service_factory.dart       # Factory para seleção
│   ├── mobile_audio_service.dart        # Android/iOS
│   ├── web_audio_service.dart           # Browser
│   └── desktop_audio_service.dart       # Windows/macOS/Linux
├── providers/
│   └── audio_provider.dart              # Gerenciamento de estado
├── models/
│   └── audio_state.dart                 # Estados do sistema
└── widgets/
    ├── mobile_audio_input_widget.dart   # Interface mobile
    └── audio_input_widget.dart          # Interface padrão
```

## 🔧 Implementações por Plataforma

### 📱 **MobileAudioService**
```dart
// Recursos específicos mobile
- Gravação com pausa/retomada nativa
- Permissões de microfone
- Armazenamento em Documents Directory
- Suporte a formatos AAC/M4A
- Interface adaptativa (compacta/completa)
```

### 🌐 **WebAudioService**
```dart
// Recursos específicos web
- MediaRecorder API nativa
- Armazenamento em localStorage
- Formato WebM para compatibilidade
- Solicitação automática de permissões
- Interface otimizada para browser
```

### 🖥️ **DesktopAudioService**
```dart
// Recursos específicos desktop
- FFmpeg para gravação (cross-platform)
- Verificação de ferramentas disponíveis
- Armazenamento em sistema de arquivos
- Suporte a múltiplos formatos
- Interface desktop nativa
```

## 🎯 Interface Comum

Todas as implementações seguem a mesma interface:

```dart
abstract class AudioServiceInterface {
  // Gravação
  Future<bool> requestPermissions();
  Future<void> startRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<String?> stopRecording();
  
  // Reprodução
  Future<void> startPlayback(String filePath);
  Future<void> pausePlayback();
  Future<void> resumePlayback();
  Future<void> stopPlayback();
  Future<void> setPlaybackSpeed(PlaybackSpeed speed);
  Future<void> seekTo(Duration position);
  
  // Plataforma específica
  Future<String> getStoragePath();
  Future<void> saveAudioFile(String sourcePath, String fileName);
  Future<bool> deleteAudioFile(String filePath);
  Future<List<String>> getAudioFiles();
}
```

## 🏭 Factory Pattern

```dart
class AudioServiceFactory {
  static AudioServiceInterface create() {
    if (kIsWeb) return WebAudioService();
    else if (Platform.isAndroid || Platform.isIOS) return MobileAudioService();
    else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) 
      return DesktopAudioService();
  }
}
```

## 📱 Interfaces de Usuário

### **Mobile - Duas Opções**

#### 1. **Interface Compacta**
- Timer horizontal
- Controles em linha
- Ideal para telas pequenas
- Botões menores

#### 2. **Interface Completa**
- Layout vertical
- Botões grandes
- Mais informações visuais
- Ideal para tablets

### **Web/Desktop - Interface Padrão**
- Layout otimizado para mouse/touchpad
- Controles maiores
- Informações detalhadas
- Compatível com teclado

## 🔄 Fluxo de Funcionamento

### **1. Detecção de Plataforma**
```dart
// Factory detecta automaticamente
final audioService = AudioServiceFactory.create();
```

### **2. Solicitação de Permissões**
```dart
// Cada plataforma gerencia suas permissões
await audioService.requestPermissions();
```

### **3. Gravação**
```dart
// Interface comum, implementação específica
await audioService.startRecording();
await audioService.pauseRecording();
await audioService.resumeRecording();
final path = await audioService.stopRecording();
```

### **4. Armazenamento**
```dart
// Cada plataforma usa seu método
final storagePath = await audioService.getStoragePath();
await audioService.saveAudioFile(sourcePath, fileName);
```

### **5. Reprodução**
```dart
// Interface comum para todas as plataformas
await audioService.startPlayback(filePath);
await audioService.setPlaybackSpeed(PlaybackSpeed.x1_5);
```

## 🎨 Widgets Adaptativos

### **MobileAudioInputWidget**
```dart
// Duas interfaces disponíveis
MobileAudioInputWidget(
  useCompactInterface: true,  // Interface compacta
  // ou
  useCompactInterface: false, // Interface completa
)
```

### **AudioInputWidget**
```dart
// Interface padrão para web/desktop
AudioInputWidget(
  onAudioMessageSent: handleAudio,
  onCancel: cancelRecording,
)
```

## 📊 Recursos por Plataforma

| Recurso | Mobile | Web | Desktop |
|---------|--------|-----|---------|
| Gravação | ✅ Nativa | ✅ MediaRecorder | ✅ FFmpeg |
| Pausa/Retomada | ✅ Nativa | ✅ Nativa | ✅ Process |
| Permissões | ✅ Automática | ✅ Automática | ✅ Verificação |
| Armazenamento | ✅ Sistema | ✅ localStorage | ✅ Sistema |
| Formatos | AAC/M4A | WebM | WAV/MP3 |
| Interface | 2 Opções | 1 Padrão | 1 Padrão |

## 🚀 Vantagens da Arquitetura

### **1. Separação de Responsabilidades**
- Cada plataforma gerencia seus recursos
- Interface comum garante consistência
- Fácil manutenção e extensão

### **2. Otimização por Plataforma**
- Mobile: Recursos nativos otimizados
- Web: APIs nativas do browser
- Desktop: Ferramentas do sistema

### **3. Escalabilidade**
- Fácil adição de novas plataformas
- Implementações independentes
- Testes isolados por plataforma

### **4. Manutenibilidade**
- Código organizado por plataforma
- Interface comum bem definida
- Factory pattern para seleção

## 🔧 Configuração por Plataforma

### **Android**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### **iOS**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Acesso ao microfone para gravação</string>
```

### **Web**
```html
<!-- Permissões automáticas via MediaRecorder -->
```

### **Desktop**
```bash
# Instalar FFmpeg
# macOS: brew install ffmpeg
# Ubuntu: sudo apt install ffmpeg
# Windows: Download do site oficial
```

## 🧪 Testagem por Plataforma

### **1. Android**
```bash
flutter run -d android
# Testar gravação, pausa, retomada
# Verificar permissões
# Testar armazenamento
```

### **2. iOS**
```bash
flutter run -d ios
# Testar gravação, pausa, retomada
# Verificar permissões
# Testar armazenamento
```

### **3. Web**
```bash
flutter run -d chrome
# Testar MediaRecorder
# Verificar localStorage
# Testar permissões do browser
```

### **4. Desktop**
```bash
flutter run -d macos  # ou windows/linux
# Verificar FFmpeg
# Testar gravação via processo
# Verificar armazenamento local
```

## 🔮 Próximas Melhorias

- [ ] **Waveform em tempo real** por plataforma
- [ ] **Compressão adaptativa** baseada na plataforma
- [ ] **Sincronização** entre plataformas
- [ ] **Backup automático** de áudios
- [ ] **Transmissão em tempo real** (WebRTC)
- [ ] **Edição de áudio** nativa por plataforma

## 🐛 Solução de Problemas

### **Mobile**
- Verificar permissões no sistema
- Testar em dispositivo real (não emulador)
- Verificar espaço de armazenamento

### **Web**
- Testar em diferentes navegadores
- Verificar HTTPS para MediaRecorder
- Limpar localStorage se necessário

### **Desktop**
- Instalar FFmpeg no sistema
- Verificar permissões de microfone
- Testar diferentes formatos de áudio

Esta arquitetura garante que cada plataforma use os recursos mais adequados disponíveis, mantendo uma experiência consistente para o usuário final.

