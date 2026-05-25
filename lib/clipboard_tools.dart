import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'clipboard_tools_platform_interface.dart';

class ClipboardTools {
  static const String _lastClipboardTimestampKey =
      'clipboard_tools.last_clipboard_timestamp';

  num? _lastClipboardTimestamp;
  Future<SharedPreferences>? _preferencesFuture;
  Future<void>? _loadLastClipboardTimestampFuture;

  Future<String?> getPlatformVersion() {
    return ClipboardToolsPlatform.instance.getPlatformVersion();
  }

  Future<String?> getClipboardContent() {
    return ClipboardToolsPlatform.instance.getClipboardContent();
  }

  Future<num?> _getClipboardTimestamp() {
    return ClipboardToolsPlatform.instance.getClipboardTimestamp();
  }

  Future<bool?> _getChangeContent() {
    return ClipboardToolsPlatform.instance.getChangeContent();
  }

  Future<void> _ensureLastClipboardTimestampLoaded() {
    return _loadLastClipboardTimestampFuture ??= () async {
      final preferences = await _getPreferences();
      final storedTimestamp =
          preferences.getString(_lastClipboardTimestampKey);
      _lastClipboardTimestamp =
          storedTimestamp == null ? null : num.tryParse(storedTimestamp);
    }();
  }

  Future<SharedPreferences> _getPreferences() {
    return _preferencesFuture ??= SharedPreferences.getInstance();
  }

  Future<void> _setLastClipboardTimestamp(num timestamp) async {
    _lastClipboardTimestamp = timestamp;
    final preferences = await _getPreferences();
    await preferences.setString(
      _lastClipboardTimestampKey,
      timestamp.toString(),
    );
  }

  /// Check if clipboard content has changed.
  /// On iOS: native plugin uses UIPasteboard.changeCount and returns bool (lastIdentifier ignored).
  /// On Android: compares getClipboardTimestamp() with last value (unchanged).
  Future<bool> hasClipboardChanged() async {
    if (Platform.isIOS) {
      return await _getChangeContent() ?? false;
    } else if (Platform.isAndroid) {
      await _ensureLastClipboardTimestampLoaded();
      final currentTimestamp = await _getClipboardTimestamp();
      if (currentTimestamp == null) {
        return false;
      } else if (_lastClipboardTimestamp == null) {
        await _setLastClipboardTimestamp(currentTimestamp);
        return true;
      } else {
        final hasChanged = _lastClipboardTimestamp != currentTimestamp;
        await _setLastClipboardTimestamp(currentTimestamp);
        return hasChanged;
      }
    } else {
      return false;
    }
  }
}
