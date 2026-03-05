package com.example.clipboard_tools

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import java.security.MessageDigest

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ClipboardToolsPlugin */
class ClipboardToolsPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var clipboardManager: ClipboardManager? = null

  private var eventSink: EventChannel.EventSink? = null
  private lateinit var eventChannel: EventChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "clipboard_tools")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "clipboard_tools/events")
    eventChannel.setStreamHandler(this)

    applicationContext = flutterPluginBinding.applicationContext
    clipboardManager = applicationContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
  }



  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "getClipboardContent") {
      val clipboardContent = getClipboardContent()
      sendToFlutter(mapOf(
        "type" to "getClipboardContent",
        "content" to (clipboardContent ?: "")
      ))
      result.success(clipboardContent)
    } else if (call.method == "getClipboardTimestamp") {
      val t = getClipboardTimestamp()
      sendToFlutter(mapOf(
        "type" to "getClipboardTimestamp",
        "content" to (t ?: "")
      ))
      result.success(t)
    } else {
      result.notImplemented()
    }
  }

  private fun getClipboardContent(): String? {
    val clipData = clipboardManager?.primaryClip
    
    if (clipData != null && clipData.itemCount > 0) {
      val item = clipData.getItemAt(0)
      return item.text?.toString()
    }
    return null
  }

  private fun getClipboardTimestamp(): Long? {
    val clipDesc = clipboardManager?.primaryClipDescription
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        clipDesc?.timestamp
    } else {
        -1
    }
  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun sendToFlutter(data: Map<String, Any>) {
    eventSink?.success(data)
  }
}
