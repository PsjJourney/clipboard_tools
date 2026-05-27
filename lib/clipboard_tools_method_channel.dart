import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'clipboard_tools_platform_interface.dart';

/// An implementation of [ClipboardToolsPlatform] that uses method channels.
class MethodChannelClipboardTools extends ClipboardToolsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('clipboard_tools');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  // 鸿蒙平台判断，兼容官方SDK
  bool get isOhos => Platform.operatingSystem == 'ohos';

  @override
  Future<String?> getClipboardContent() async {
    if(isOhos){
      try{
        final content =
        await methodChannel.invokeMethod<String>('getClipboardContent');
        debugPrint('clipboard_tools: getClipboardContent -> $content');
        return Future.value(content);
      } catch(e){
        debugPrint('clipboard_tools: getClipboardContent Error-> $e');
      }
      return Future.value(null);
    }
    final version =
        await methodChannel.invokeMethod<String>('getClipboardContent');
    return version;
  }

  @override
  Future<num?> getClipboardTimestamp() async {
    if (Platform.isAndroid) {
      final timestamp =
          await methodChannel.invokeMethod<num>('getClipboardTimestamp');
      return timestamp;
    } else if (isOhos) {
      try {
        final timestamp = await methodChannel.invokeMethod<num?>('getClipboardTimestamp');
        debugPrint('clipboard_tools: getClipboardTimestamp -> $timestamp');
        return Future.value(timestamp);
      } catch (e) {
        debugPrint('clipboard_tools: getClipboardTimestamp -> $e');
        return Future.value(null);
      }
    } else {
      return null;
    }
  }

  @override
  Future<bool?> getChangeContent() async {
    if (Platform.isIOS) {
      final result = await methodChannel.invokeMethod<bool>('getChangeContent');
      return result ?? false;
    } else {
      return null;
    }
  }
}
