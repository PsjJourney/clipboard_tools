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
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> getClipboardContent() async {
    final version = await methodChannel.invokeMethod<String>('getClipboardContent');
    return version;
  }

  @override
  Future<num?> getClipboardTimestamp() async {
    final timestamp = await methodChannel.invokeMethod<num>('getClipboardTimestamp');
    return timestamp;
  }

  @override
  Future<bool> hasClipboardChanged(String lastIdentifier) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await methodChannel.invokeMethod<bool>('hasClipboardChanged');
      return result ?? false;
    }
    final currentIdentifier = await methodChannel.invokeMethod<String>('getClipboardIdentifier');
    return currentIdentifier != lastIdentifier;
  }
}
