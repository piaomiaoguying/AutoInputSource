import SwiftUI

class MenuBarViewModel: ObservableObject {
    @Published var isPopoverShown = false
    
    // 用于控制弹出窗口的显示状态
    func togglePopover() {
        isPopoverShown.toggle()
    }
}

struct MenuBarView: View {
    @StateObject private var viewModel = MenuBarViewModel()
    
    var body: some View {
        // 空视图作为状态栏图标的容器
        EmptyView()
            .frame(width: 0, height: 0)
            .onAppear {
                // 设置状态栏图标
                if let statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength) {
                    if let button = statusBar.button {
                        button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Input Source")
                        button.action = #selector(NSApplication.shared.togglePopover(_:))
                        button.target = NSApplication.shared
                    }
                }
            }
    }
} 