import 'dart:io';
import 'package:flutter/foundation.dart';
import 'audio_service_interface.dart';
import 'mobile_audio_service.dart';
import 'web_audio_service.dart';
import 'desktop_audio_service.dart';

class AudioServiceFactory {
    static AudioServiceInterface create() {
    if (kIsWeb) {
      return WebAudioService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return MobileAudioService();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return DesktopAudioService();
    } else {
      // Fallback para plataformas não suportadas
      throw UnsupportedError('Plataforma não suportada para áudio');
    }
  }
  
  static String getPlatformName() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }
  
  static bool isMobile() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
  
  static bool isDesktop() {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
  
  static bool isWeb() {
    return kIsWeb;
  }
}

