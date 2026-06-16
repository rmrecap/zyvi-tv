import 'package:flutter/services.dart';

class PipService {
  static const _channel = MethodChannel('com.example.zyvi_tv/pip');

  static Future<bool> get isSupported async {
    try {
      return await _channel.invokeMethod('isPipSupported') as bool;
    } catch (_) {
      return false;
    }
  }

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enablePip');
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disablePip');
    } catch (_) {}
  }

  static Future<void> enterPictureInPicture() async {
    try {
      await _channel.invokeMethod('enterPictureInPicture');
    } catch (_) {}
  }
}
