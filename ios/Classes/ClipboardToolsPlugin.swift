import Flutter
import UIKit
import CommonCrypto

public class ClipboardToolsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var channel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?
  private var lastChangeCount: Int?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "clipboard_tools", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "clipboard_tools/events", binaryMessenger: registrar.messenger())

    let instance = ClipboardToolsPlugin()
    instance.channel = channel

    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)

    instance.eventChannel = eventChannel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getClipboardContent":
      let content = getClipboardContent()
      let text = content ?? ""
      log(message: "getClipboardContent: " + text)
      sendToFlutter(type: "getClipboardContent", content: text)
      result(content)
    case "getChangeContent":
      let changed = getChangeContent()
      log(message: "getChangeContent: \(changed)")
      sendToFlutter(type: "getChangeContent", content: changed)
      result(changed)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getClipboardContent() -> String? {
    let pasteboard = UIPasteboard.general
    if let string = pasteboard.string {
      return string
    }
    return nil
  }

  private func getChangeContent() -> Bool {
    let currentCount = UIPasteboard.general.changeCount

    // First time: just record, do not treat as changed
    guard let last = lastChangeCount else {
      lastChangeCount = currentCount
      return false
    }

    let changed = currentCount != last
    if changed {
      lastChangeCount = currentCount
    }
    return changed
  }

  private func sendToFlutter(type: String, content: Any) {
    eventSink?(["type": type, "content": content])
  }

  private func currentMillis() -> Int64 {
    return Int64(Date().timeIntervalSince1970 * 1000)
  }

  private func md5Hash(_ input: String) -> String {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    let messageData = input.data(using: .utf8) ?? Data()
    var digestData = Data(count: length)

    _ = digestData.withUnsafeMutableBytes { digestBytes in
      messageData.withUnsafeBytes { messageBytes in
        CC_MD5(messageBytes.baseAddress,
               CC_LONG(messageData.count),
               digestBytes.bindMemory(to: UInt8.self).baseAddress)
      }
    }

    return digestData.map { String(format: "%02x", $0) }.joined()
  }

  private func log(message: String) {
    print("[ClipboardTools][iOS] \(message)")
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
