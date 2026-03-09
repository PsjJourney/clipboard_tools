import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'clipboard_tools_method_channel.dart';

abstract class ClipboardToolsPlatform extends PlatformInterface {
  /// Constructs a ClipboardToolsPlatform.
  ClipboardToolsPlatform() : super(token: _token);

  static final Object _token = Object();

  static ClipboardToolsPlatform _instance = MethodChannelClipboardTools();

  /// The default instance of [ClipboardToolsPlatform] to use.
  ///
  /// Defaults to [MethodChannelClipboardTools].
  static ClipboardToolsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ClipboardToolsPlatform] when
  /// they register themselves.
  static set instance(ClipboardToolsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> getClipboardContent() {
    throw UnimplementedError('getClipboardContent() has not been implemented.');
  }

  Future<num?> getClipboardTimestamp() {
    throw UnimplementedError('getClipboardTimestamp() has not been implemented.');
  }

  Future<bool?> getChangeContent() {
    throw UnimplementedError('getChangeContent() has not been implemented.');
  }
}
