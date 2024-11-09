//
//  UserAppConfig.swift
//  AutoInputSource
//
//  Created by 梁波 on 2024/3/18.
//

import Cocoa
import SwiftUI

import Foundation
import AppKit


struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    var icon: NSImage?
    var bundleIdentifier: String
    var shouldSwitchInputMethod: Bool = false
    var selectedInputMethod: String = ""
}

class AppListViewModel: ObservableObject {
  @Published var appList: [AppInfo] = []

  init() {

    var userAppImeConfig: [String: String] = [:]

    if let userAppImeConfigTmp: [String: String] = DictionaryManager.shared.loadDictionary(
      forKey: "UserAppImeConfigDictionary")
    {
      //            print("userAppImeConfig: \(userAppImeConfigTmp)")
      userAppImeConfig = userAppImeConfigTmp
    } else {
      print("No userAppImeConfig info found.")
    }

    //        let runningApplications = NSWorkspace.shared.runningApplications
    let runningApplications = NSWorkspace.shared.runningApplications.filter { app in
      return app.activationPolicy == .regular
    }
    for app in runningApplications {
      if let appName = app.localizedName,
        let bundleIdentifier = app.bundleIdentifier
      {

        if let ime = userAppImeConfig[bundleIdentifier] {
          let appInfo = AppInfo(
            name: appName, icon: app.icon, bundleIdentifier: bundleIdentifier,
            selectedInputMethod: ime)
          appList.append(appInfo)
        } else {
          let appInfo = AppInfo(name: appName, icon: app.icon, bundleIdentifier: bundleIdentifier)
          appList.append(appInfo)
        }

        //                if(appName == "微信") {
        //                    let appInfo = AppInfo(name: appName, icon: app.icon,bundleIdentifier: bundleIdentifier,selectedInputMethod: "com.tencent.inputmethod.wetype.pinyin")
        //
        //                    appList.append(appInfo)
        //                } else {
        //                    let appInfo = AppInfo(name: appName, icon: app.icon,bundleIdentifier: bundleIdentifier)
        //
        //                    appList.append(appInfo)
        //                }

      }
    }

  }
}

struct ConfigRow: View {
    var appInfo: AppInfo
    @Binding var shouldSwitchInputMethod: Bool
    @Binding var selectedInputMethod: String
    // 创建一个可变的输入法选项字典
    var inputMethodOptions: [String: String]

    init(
        appInfo: AppInfo, 
        shouldSwitchInputMethod: Binding<Bool>, 
        selectedInputMethod: Binding<String>,
        inputMethodOptions: [String: String]
    ) {
        self.appInfo = appInfo
        self._shouldSwitchInputMethod = shouldSwitchInputMethod
        self._selectedInputMethod = selectedInputMethod
        
        // 创建一个新的字典，包含原有选项和空选项
        var options = inputMethodOptions
        options[""] = ""
        self.inputMethodOptions = options
    }

    var body: some View {
        HStack {
            if let icon = appInfo.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
            }
            Text(appInfo.name)
            Spacer()
            
            Picker("", selection: $selectedInputMethod) {
                ForEach(inputMethodOptions.keys.sorted(), id: \.self) { key in
                    Text(inputMethodOptions[key] ?? "")
                        .tag(key)
                }
            }
            .frame(width: 100)
            .labelsHidden()
            .onChange(of: selectedInputMethod) { _, newValue in
                handleInputMethodSelectionChange(appInfo: appInfo, newValue: newValue)
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
    }
}

struct UserAppConfig: View {
  @ObservedObject var viewModel = AppListViewModel()
  @State private var selectedMethods: [String] = []

  var body: some View {
    VStack {
      List(viewModel.appList.indices, id: \.self) { index in
        if let inputMethodOptions: [String: String] = DictionaryManager.shared.loadDictionary(
          forKey: "KeyboardIdentifier")
        {
          ConfigRow(
            appInfo: viewModel.appList[index],
            shouldSwitchInputMethod: self.$viewModel.appList[index].shouldSwitchInputMethod,
            selectedInputMethod: self.$viewModel.appList[index].selectedInputMethod,
            inputMethodOptions: inputMethodOptions)
        }
      }
      .frame(
        minWidth: 300, idealWidth: 400, maxWidth: .infinity, minHeight: 200, idealHeight: 300,
        maxHeight: .infinity)
    }
  }
}

// 当输入法选择变化时调用的方法
private func handleInputMethodSelectionChange(appInfo: AppInfo, newValue: String) {
  //        selectedInputMethod = newValue
  // 在这里调用保存方法
  print(newValue)
  print(appInfo.bundleIdentifier)

  // 将配置持久化存储
  if newValue == "" {
    DictionaryManager.shared.removeKey(
      key: appInfo.bundleIdentifier, forKey: "UserAppImeConfigDictionary")
  } else {
    DictionaryManager.shared.addKeyValue(
      key: appInfo.bundleIdentifier, value: newValue, forKey: "UserAppImeConfigDictionary")
  }

}

#Preview{
  UserAppConfig()
}
