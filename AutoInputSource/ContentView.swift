//
//  ContentView.swift
//  AutoInputSource
//
//  Created by 梁波 on 2024/3/16.
//

import Carbon
import SwiftUI

// 在文件开头定义 Logger
struct Logger {
    static func debug(_ message: String) {
        #if DEBUG
        print("🔍 Debug: \(message)")
        #endif
    }
    
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ Info: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ Warning: \(message)")
        #endif
    }
    
    static func error(_ message: String) {
        #if DEBUG
        print("❌ Error: \(message)")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ Success: \(message)")
        #endif
    }
}

struct ContentView: View {
  @ObservedObject var applicationObserver = ApplicationObserver()

  @State private var isi: TISInputSource?

  @State var inputSourcesDictionary: [String: TISInputSource] = [:]

  @State var inputSources: [TISInputSource] = []
    

  var body: some View {
      VStack {
          UserAppConfig()
          
          HStack {
              Text("当前应用: \(applicationObserver.currentApplication?.localizedName ?? "Unknown")")
              Spacer()
              Button(action: {
                  NSApplication.shared.terminate(nil)
              }) {
                  Text("退出")
                      .foregroundColor(.white)
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)
                      .background(Color.red.opacity(0.8))
                      .cornerRadius(6)
              }
              .buttonStyle(PlainButtonStyle())
          }
          .padding()
      }
  }
}

class ApplicationObserver: ObservableObject {
  @Published var currentApplication: NSRunningApplication?
  private var workspaceNotification: NSObjectProtocol?

  init() {

    self.workspaceNotification = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
    ) { [weak self] notification in
      self?.currentApplication =
        notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                  self?.switchInputMethodIfNeeded() // 在这里调用切换输入法的方法

    }
  }

  private func switchInputMethodIfNeeded() {
    guard let currentApplication = currentApplication else { return }
    
    Logger.info("切换应用：\(currentApplication.localizedName ?? "Unknown")(\(currentApplication.bundleIdentifier ?? "Unknown"))")

    var userAppImeConfig: [String: String] = [:]
    
    if let userAppImeConfigTmp: [String: String] = DictionaryManager.shared.loadDictionary(
      forKey: "UserAppImeConfigDictionary")
    {
      userAppImeConfig = userAppImeConfigTmp
    }

    // 根据当前应用切换输入法
    if let currentApp = currentApplication.bundleIdentifier,
       let targetIME = userAppImeConfig[currentApp]
    {
        Logger.info("找到应用配置，目标输入法ID：\(targetIME)")
        
        // 直接使用系统 API 获取输入法
        if let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] {
            // 获取切换前的输入法状态
            if let currentInputSource = getCurrentInputSource() {
                Logger.info("当前输入法：\(currentInputSource.localizedName)")
            }
            
            // 查找目标输入法
            for inputSource in inputSourceList {
                if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                    let id = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
                    if id == targetIME {
                        Logger.success("找到目标输入法：\(inputSource.localizedName)")
                        
                        // 切换输入法
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            setInputSource(inputSource: inputSource)
                            
                            // 获取切换后的输入法状态
                            if let newInputSource = getCurrentInputSource() {
                                Logger.info("切换后输入法：\(newInputSource.localizedName)")
                            }
                        }
                        break
                    }
                }
            }
        }
    } else {
        Logger.warning("当前应用没有配置输入法")
    }
  }

  deinit {
    if let observer = self.workspaceNotification {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}

//func simulateClickOnNavigationBar() {
//    let navigationBarLocation = NSPoint(x: -1, y: 1) // 替换为屏幕顶部导航栏的位置
//
//    // 创建鼠标点击事件
//    let mouseClickEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: navigationBarLocation, mouseButton: .left)!
//    mouseClickEvent.post(tap: .cghidEventTap)
//}

// 设置输入法
func setInputSource(inputSource: TISInputSource) {
    Logger.info("准备切换输入法到：\(inputSource.localizedName)")
    let result = TISSelectInputSource(inputSource)
    if result != noErr {
        Logger.error("输入法切换失败：\(inputSource.localizedName)，错误码：\(result)")
    } else {
        Logger.success("输入法切换成功：\(inputSource.localizedName)")
    }
}

func getDefaultInputSource() -> TISInputSource? {
    if let _ = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
       let defaultInputSource = getInputSource(for: "com.apple.keylayout.ABC") {
        return defaultInputSource
    }
    Logger.warning("无法获取默认输入法")
    return nil
}

func getCurrentInputSource() -> TISInputSource? {
    guard let currentKeyboardInputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
        return nil
    }
    
    return currentKeyboardInputSource
}

func activateApplication(app: String) {
    let workspace = NSWorkspace.shared
    if let appURL = workspace.urlForApplication(withBundleIdentifier: app) {
        let configuration = NSWorkspace.OpenConfiguration()
        workspace.openApplication(at: appURL,
                                configuration: configuration) { _, error in
            if let error = error {
                Logger.error("启动应用失败：\(error.localizedDescription)")
            }
        }
    }
}

#Preview{
  ContentView()
}







import InputMethodKit

// MARK: - TISInputSource Extension by The vChewing Project (MIT License).

extension TISInputSource {
  public static var allRegisteredInstancesOfThisInputMethod: [TISInputSource] {
    TISInputSource.modes.compactMap { TISInputSource.generate(from: $0) }
  }

  public static var modes: [String] {
    guard let components = Bundle.main.infoDictionary?["ComponentInputModeDict"] as? [String: Any],
      let tsInputModeListKey = components["tsInputModeListKey"] as? [String: Any]
    else {
      return []
    }
    return tsInputModeListKey.keys.map { $0 }
  }

  @discardableResult public static func registerInputMethod() -> Bool {
    let instances = TISInputSource.allRegisteredInstancesOfThisInputMethod
    if instances.isEmpty {
      // No instance registered, proceeding to registration process.
      NSLog("Registering input source.")
      if !TISInputSource.registerInputSource() {
        NSLog("Input source registration failed.")
        return false
      }
    }
    var succeeded = true
    instances.forEach {
      NSLog("Enabling input source: \($0.identifier)")
      if !$0.activate() {
        NSLog("Failed from enabling input source: \($0.identifier)")
        succeeded = false
      }
    }
    return succeeded
  }

  @discardableResult public static func registerInputSource() -> Bool {
    TISRegisterInputSource(Bundle.main.bundleURL as CFURL) == noErr
  }

  @discardableResult public func activate() -> Bool {
    TISEnableInputSource(self) == noErr
  }

  @discardableResult public func select() -> Bool {
    if !isSelectable {
      NSLog("Non-selectable: \(identifier)")
      return false
    }
    if TISSelectInputSource(self) != noErr {
      NSLog("Failed from switching to \(identifier)")
      return false
    }
    return true
  }

  @discardableResult public func deactivate() -> Bool {
    TISDisableInputSource(self) == noErr
  }

  public var isActivated: Bool {
    unsafeBitCast(TISGetInputSourceProperty(self, kTISPropertyInputSourceIsEnabled), to: CFBoolean.self)
      == kCFBooleanTrue
  }

  public var isSelectable: Bool {
    unsafeBitCast(TISGetInputSourceProperty(self, kTISPropertyInputSourceIsSelectCapable), to: CFBoolean.self)
      == kCFBooleanTrue
  }

  public static func generate(from identifier: String) -> TISInputSource? {
    TISInputSource.rawTISInputSources(onlyASCII: false)[identifier] ?? nil
  }

  public var inputModeID: String {
    unsafeBitCast(TISGetInputSourceProperty(self, kTISPropertyInputModeID), to: NSString.self) as String
  }
}

// MARK: - TISInputSource Extension by Mizuno Hiroki (a.k.a. "Mzp") (MIT License)

// Ref: Original source codes are written in Swift 4 from Mzp's InputMethodKit textbook.
// Note: Slightly modified by vChewing Project: Using Dictionaries when necessary.

extension TISInputSource {
  public var localizedName: String {
    unsafeBitCast(TISGetInputSourceProperty(self, kTISPropertyLocalizedName), to: NSString.self) as String
  }

  public var identifier: String {
    unsafeBitCast(TISGetInputSourceProperty(self, kTISPropertyInputSourceID), to: NSString.self) as String
  }

  public var scriptCode: Int {
    let r = TISGetInputSourceProperty(self, "TSMInputSourcePropertyScriptCode" as CFString)
    return unsafeBitCast(r, to: NSString.self).integerValue
  }

  public static func rawTISInputSources(onlyASCII: Bool = false) -> [String: TISInputSource] {
    // Build a CFDictionary for specifying filter conditions.
    // The 2nd parameter indicates the capacity of this CFDictionary.
    let conditions = CFDictionaryCreateMutable(nil, 2, nil, nil)
    if onlyASCII {
      // Condition 1: isTISTypeKeyboardLayout?
      CFDictionaryAddValue(
        conditions, unsafeBitCast(kTISPropertyInputSourceType, to: UnsafeRawPointer.self),
        unsafeBitCast(kTISTypeKeyboardLayout, to: UnsafeRawPointer.self)
      )
      // Condition 2: isASCIICapable?
      CFDictionaryAddValue(
        conditions, unsafeBitCast(kTISPropertyInputSourceIsASCIICapable, to: UnsafeRawPointer.self),
        unsafeBitCast(kCFBooleanTrue, to: UnsafeRawPointer.self)
      )
    }
    // Return the results.
    var result = TISCreateInputSourceList(conditions, true).takeRetainedValue() as? [TISInputSource] ?? .init()
    if onlyASCII {
      result = result.filter { $0.scriptCode == 0 }
    }
    var resultDictionary: [String: TISInputSource] = [:]
    result.forEach {
      resultDictionary[$0.inputModeID] = $0
      resultDictionary[$0.identifier] = $0
    }
    return resultDictionary
  }
}
