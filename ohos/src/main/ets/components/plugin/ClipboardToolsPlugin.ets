import {
  AbilityAware,
  AbilityPluginBinding,
  Any,
  EventChannel,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { pasteboard } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';


/** ClipboardToolsPlugin **/
export default class ClipboardToolsPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private uiAbilityContext: common.UIAbilityContext | null = null;
  private eventChannel: EventChannel | null = null;
  private streamHandler: EventStreamHandler | null = null;

  constructor() {
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiAbilityContext = binding.getAbility().context;
    console.log('[CBTPlugin] UIAbilityContext acquired successfully');
    // this.startMonitoring();
  }

  onDetachedFromAbility(): void {
    this.uiAbilityContext = null;
    console.log('[CBTPlugin] UIAbilityContext released');
    // this.stopMonitoring();
  }

  getUniqueClassName(): string {
    return "ClipboardToolsPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "clipboard_tools");
    this.channel.setMethodCallHandler(this)
    // 初始化事件通道
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), 'clipboard_tools/events');
    this.streamHandler = new EventStreamHandler();
    this.eventChannel.setStreamHandler(this.streamHandler);
  }


  sendToFlutter(map: Map<string, Any>): void {
    this.streamHandler?.sendToFlutter(map)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    if(this.eventChannel != null){
      this.eventChannel.setStreamHandler(null)
      this.streamHandler = null;
    }
    console.log('[CBTPlugin] onDetachedFromEngine');
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "getPlatformVersion") {
      result.success("OpenHarmony ^ ^ ")
    } else if (call.method == "getClipboardContent") {
      this.checkPermissionGrant(result, 1)
      // result.success('内容')
    }  else if (call.method == "getClipboardTimestamp") {
      this.checkPermissionGrant(result, 0)
    } else {
      result.notImplemented()
    }
  }


  // 获取剪切板数据，前提需要检查权限
  async getPasteData(result: MethodResult, type: number): Promise<void> {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();

    systemPasteboard.hasData((err, data) => {
      if (err) {
        hilog.info(0x0000, '[CBTPlugin]', `Failed to check the PasteData. Cause: ${err.message}`);
        result.error(err.name, err.message, err.stack)
        return;
      }
      hilog.info(0x0000, '[CBTPlugin]', `Succeeded in checking the PasteData. Data: ${data}`);
      if(data){
        systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
          if(type === 0){
            let timestamp = pasteData.getProperty().timestamp;
            hilog.info(0x0000, '[CBTPlugin]', `get timestamp: ${timestamp}`);

            let data = new Map<string, string | number>();
            data.set('type', 'getClipboardTimestamp');
            data.set('content', timestamp);
            this.sendToFlutter(data);

            result.success(timestamp);//单位：已开机时间的ns数
          } else {
            let text = pasteData.getPrimaryText();
            hilog.info(0x0000, '[CBTPlugin]', `getPrimaryText: ${text}`);

            let data = new Map<string, string | number>();
            data.set('type', 'getClipboardContent');
            data.set('content', text);
            this.sendToFlutter(data);

            result.success(text);
          }
        }).catch((err: Error) => {
          hilog.error(0x0000, '[CBTPlugin]', 'Failed to get PasteData. Cause: ' + err.message);
          result.error(`${err.name}`, err.message, err.stack);
        })
      } else {
        hilog.info(0x0000, '[CBTPlugin]', `systemPasteboard no data`);
        let data = new Map<string, string | number | null>();
        data.set('type', type === 0 ? 'getClipboardTimestamp' : 'getClipboardContent');
        data.set('content', null);
        this.sendToFlutter(data);
        result.success(null)
        // result.error('', 'systemPasteboard no data', '')
      }
    });

  }

  // 校验权限
  checkPermissionGrant(result: MethodResult, type: number): void {
    let hasPermission = false;
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      const err: Error = error as Error;
      hilog.error(0x0000, '[CBTPlugin]',
        `Failed to get bundle info for self. Code is ${err.name}, message is ${err.message}`);
    }

    try {
      let atManager = abilityAccessCtrl.createAtManager();
      let approximatelyLocation = atManager.checkAccessTokenSync(tokenId, 'ohos.permission.READ_PASTEBOARD');
      hasPermission = approximatelyLocation === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      const err: Error = error as Error;
      hilog.error(0x0000, '[CBTPlugin]', `Failed to check access token. Code is ${err.name}, message is ${err.message}`);
    }
    if (hasPermission) {
      hilog.info(0x0000, '[CBTPlugin]', 'has Permissions!');
      this.getPasteData(result, type)
    } else {
      hilog.error(0x0000, '[CBTPlugin]', 'The app is not authorized.');
      this.requestPermissionsFn(result, type);
    }
  }

  // 申请权限
  requestPermissionsFn(result: MethodResult, type: number): void {
    let atManager = abilityAccessCtrl.createAtManager();
    if(this.uiAbilityContext != null) {
      atManager.requestPermissionsFromUser(this.uiAbilityContext, [
        'ohos.permission.READ_PASTEBOARD'
      ]).then((data: PermissionRequestResult): void => {
        if (data.authResults.toString() === '0') {
          hilog.info(0x0000, '[CBTPlugin]', 'request Permissions success!');
          this.getPasteData(result, type)
        } else {
          hilog.error(0x0000, '[CBTPlugin]', 'request Permissions fail! result:' + data.authResults.toString());
          result.error('', `request Permissions fail! result: ${data.authResults.toString()}}`, '');
        }
      }).catch((error: Error): void => {
        hilog.error(0x0000, '[CBTPlugin]', `requestPermissionsFromUser call Failed! error: ${error.name}`);
        result.error(`${error.name}`, error.message, error.stack);
      });
    } else {
      hilog.error(0x0000, '[CBTPlugin]', `requestPermissionsFn context null`);
      result.error('', 'requestPermissionsFn context null', '');
    }
  }

  //
  // startMonitoring() {
  //   if (this.isMonitoring) return;
  //
  //   try {
  //     this.systemPasteboard.on('update', this.listener);
  //   } catch (error) {
  //     console.error("[CBTPlugin]on listener update error:", error);
  //   }
  //   this.isMonitoring = true;
  //   console.log("[CBTPlugin]开始监听剪切板变化");
  // }
  //
  // stopMonitoring() {
  //   if (!this.isMonitoring) return;
  //
  //   // 移除监听器
  //   try {
  //     this.systemPasteboard.off('update', this.listener);
  //   } catch (error) {
  //     console.error("[CBTPlugin]off listener update error:", error);
  //   }
  //   this.isMonitoring = false;
  //   console.log("[CBTPlugin]停止监听剪切板变化");
  // }

}


class EventStreamHandler implements StreamHandler {
  private eventSink: EventSink | null = null;

  constructor() {
  }

  onListen(args: number | null, events: EventSink): void {
    this.eventSink = events;
    console.log(`[CBTPlugin] eventChannel onListen ${events} ${this.eventSink}`);
  }

  onCancel(args: number | null): void {
    this.eventSink = null;
    console.log('[CBTPlugin] eventChannel onCancel');
  }

  sendToFlutter(map: Map<string, Any>): void {
    hilog.info(0x0000, '[CBTPlugin]', `sendToFlutter. ${this.eventSink} Data: ${map.get('type')} / ${map.get('content')}`);
    this.eventSink?.success(map);
  }

}
