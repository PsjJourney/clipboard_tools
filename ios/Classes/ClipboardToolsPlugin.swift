import Flutter
import UIKit
import CommonCrypto

public class ClipboardToolsPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  private var lastChangeCount: Int?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "clipboard_tools", binaryMessenger: registrar.messenger())
    let instance = ClipboardToolsPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getClipboardContent":
      result(getClipboardContent())
    case "getClipboardIdentifier":
      result(getClipboardIdentifier())
    case "hasClipboardChanged":
      result(hasClipboardChanged())
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

  private func getClipboardIdentifier() -> String {
    let pasteboard = UIPasteboard.general

    // If clipboard is effectively empty
    if pasteboard.string == nil &&
       pasteboard.url == nil &&
       pasteboard.image == nil &&
       pasteboard.items.isEmpty {
      return "empty_\(currentMillis())"
    }

    if let text = pasteboard.string {
      let preview = text.count > 20 ? String(text.prefix(20)) : text
      let hash = md5Hash(text)
      return "text_\(text.count)_\(preview)_\(hash)"
    }

    if let url = pasteboard.url {
      return "uri_\(url.absoluteString)"
    }

    if let htmlData = pasteboard.data(forPasteboardType: "public.html"),
       let html = String(data: htmlData, encoding: .utf8) {
      let preview = html.count > 20 ? String(html.prefix(20)) : html
      let hash = md5Hash(html)
      return "html_\(html.count)_\(preview)_\(hash)"
    }

    // Fallback similar to Android's mime_* and unknown_*
    if let types = pasteboard.types as? [String], !types.isEmpty {
      let joined = types.joined(separator: ",")
      return "mime_\(joined)_\(currentMillis())"
    }

    return "unknown_\(currentMillis())"
  }

  private func hasClipboardChanged() -> Bool {
    let currentCount = UIPasteboard.general.changeCount

    // 第一次访问时，仅记录当前值，不认为是“有变化”
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
}

