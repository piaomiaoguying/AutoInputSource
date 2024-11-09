//
//  AutoInputSourceApp.swift
//  AutoInputSource
//
//  Created by 梁波 on 2024/3/16.
//

import SwiftUI
import Carbon
import Defaults

@main
struct AutoInputSourceApp: App {
    // 添加AppDelegate来处理应用程序生命周期
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// 添加AppDelegate类来管理窗口和状态栏
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置主窗口不在Dock显示
        NSApp.setActivationPolicy(.accessory)
        
        // 配置弹出窗口
        let contentView = ContentView()
        popover.contentSize = NSSize(width: 400, height: 500) // 根据需要调整大小
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // 设置状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Input Source")
            // 直接设置按钮的动作和目标
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    // 添加切换 Popover 的方法
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                // 显示 popover 时，将其定位在状态栏图标下方
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                // 可选：让 popover 成为关键窗口
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}

// 扩展NSApplication来处理状态栏点击事件
extension NSApplication {
    @objc func togglePopover(_ sender: AnyObject?) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            if let button = appDelegate.statusItem?.button {
                if appDelegate.popover.isShown {
                    appDelegate.popover.performClose(sender)
                } else {
                    appDelegate.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }
}



func getInputSourcePropertiesOfDic() -> [String: TISInputSource] {
    var inputSourceProperties: [String: TISInputSource] = [:]
    
    if let cfArray = TISCreateInputSourceList(nil, false)?.takeRetainedValue() {
        for cf in cfArray as NSArray {
            let inputSource = cf as! TISInputSource
            
            if let inputSourceIDPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                let inputSourceID = Unmanaged<CFString>.fromOpaque(inputSourceIDPtr).takeUnretainedValue() as String
                inputSourceProperties[inputSourceID] = inputSource
            }
        }
    }
    
    return inputSourceProperties
}


func getInputSource(for identifier: String) -> TISInputSource? {
    if let cfArray = TISCreateInputSourceList(nil, false)?.takeRetainedValue() {
        for cf in cfArray as NSArray {
            let inputSource = cf as! TISInputSource

            if let inputSourceIDPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                let inputSourceID = Unmanaged<CFString>.fromOpaque(inputSourceIDPtr).takeUnretainedValue() as String
                if inputSourceID == identifier {
                    return inputSource
                }
            }
        }
    }
    return nil
}





