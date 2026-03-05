import 'package:flutter_test/flutter_test.dart';
import 'package:clipboard_tools/clipboard_tools.dart';
import 'package:clipboard_tools/clipboard_tools_platform_interface.dart';
import 'package:clipboard_tools/clipboard_tools_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockClipboardToolsPlatform
    with MockPlatformInterfaceMixin
    implements ClipboardToolsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ClipboardToolsPlatform initialPlatform = ClipboardToolsPlatform.instance;

  test('$MethodChannelClipboardTools is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelClipboardTools>());
  });

  test('getPlatformVersion', () async {
    ClipboardTools clipboardToolsPlugin = ClipboardTools();
    MockClipboardToolsPlatform fakePlatform = MockClipboardToolsPlatform();
    ClipboardToolsPlatform.instance = fakePlatform;

    expect(await clipboardToolsPlugin.getPlatformVersion(), '42');
  });
}
