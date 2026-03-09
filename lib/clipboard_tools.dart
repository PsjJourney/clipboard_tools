import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'clipboard_tools_platform_interface.dart';

class ClipboardTools {
  num? _lastClipboardTimestamp;

  Future<String?> getPlatformVersion() {
    return ClipboardToolsPlatform.instance.getPlatformVersion();
  }

  Future<String?> getClipboardContent() {
    return ClipboardToolsPlatform.instance.getClipboardContent();
  }

  Future<num?> getClipboardTimestamp() {
    return ClipboardToolsPlatform.instance.getClipboardTimestamp();
  }

  Future<bool> _getChangeContent() {
    return ClipboardToolsPlatform.instance.getChangeContent();
  }

  /// Check if clipboard content has changed.
  /// On iOS: native plugin uses UIPasteboard.changeCount and returns bool (lastIdentifier ignored).
  /// On Android: compares getClipboardTimestamp() with last value (unchanged).
  Future<bool> hasClipboardChanged() async {
    if (Platform.isIOS) {
      return await _getChangeContent();
    } else if (Platform.isAndroid) {
      final currentTimestamp = await getClipboardTimestamp();
      if (_lastClipboardTimestamp == null) {
        _lastClipboardTimestamp = currentTimestamp;
        return true;
      }
      final hasChanged = _lastClipboardTimestamp != currentTimestamp;
      _lastClipboardTimestamp = currentTimestamp;
      return hasChanged;
    } else {
      return false;
    }
  }
}
