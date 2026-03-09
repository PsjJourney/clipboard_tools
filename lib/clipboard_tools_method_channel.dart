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

  @override
  Future<String?> getClipboardContent() async {
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
