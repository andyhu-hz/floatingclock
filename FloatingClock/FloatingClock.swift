import SwiftUI
import AppKit

// 全局变量来跟踪应用程序实例
private var isAppRunning = false

// 自定义窗口类
class CustomWindow: NSWindow {
    private var windowDelegate: WindowDelegate?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // 设置窗口层级为浮动窗口
        self.level = .floating
        
        // 设置窗口标题
        self.title = "Floating Clock"
        
        // 使用系统默认标题栏，移除自定义粉色背景
        self.titlebarAppearsTransparent = false
        self.titleVisibility = .visible
        
        // 设置窗口代理
        windowDelegate = WindowDelegate()
        self.delegate = windowDelegate
    }
}

// 窗口控制器类
class CustomWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.level = .floating
    }
}

// 窗口代理类
class WindowDelegate: NSObject, NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.level = .floating
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.level = .floating
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.level = .floating
        }
    }
}

// 应用程序代理类
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: CustomWindowController?
    
    // 安全地终止之前的实例
    private func terminatePreviousInstances() {
        // 方法1: 尝试使用 pkill 命令
        if let pkillPath = findPkillPath() {
            do {
                let task = Process()
                task.launchPath = pkillPath
                task.arguments = ["-f", "FloatingClock"]
                task.launch()
                task.waitUntilExit()
            } catch {
                print("无法使用 pkill 终止进程: \(error)")
            }
        }
        
        // 方法2: 使用 NSRunningApplication 查找和终止
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.bundleIdentifier == "com.example.FloatingClock" && app != NSRunningApplication.current {
                app.terminate()
            }
        }
    }
    
    // 查找 pkill 命令的路径
    private func findPkillPath() -> String? {
        let possiblePaths = [
            "/usr/bin/pkill",
            "/bin/pkill",
            "/sbin/pkill"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // 如果找不到 pkill，尝试使用 which 命令查找
        do {
            let task = Process()
            task.launchPath = "/usr/bin/which"
            task.arguments = ["pkill"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return path
                }
            }
        } catch {
            print("无法查找 pkill 命令: \(error)")
        }
        
        return nil
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 安全地终止之前的进程
        terminatePreviousInstances()
        
        // 等待一小段时间确保进程完全终止
        Thread.sleep(forTimeInterval: 0.5)
        
        // 检查是否已经有实例在运行
        if isAppRunning {
            NSApp.terminate(nil)
            return
        }
        
        isAppRunning = true
        
        // 设置应用程序始终显示在 Dock 中
        NSApp.setActivationPolicy(.regular)
        
        // 获取屏幕尺寸
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen.main!
        let screenFrame = screen.visibleFrame
        
        // 计算窗口在右下角的位置
        let windowWidth: CGFloat = 250
        let windowHeight: CGFloat = 70
        let windowX = screenFrame.maxX - windowWidth - 20  // 距离右边缘20像素
        let windowY = screenFrame.minY + 20  // 距离下边缘20像素
        
        // 创建自定义窗口（延迟创建，避免立即显示）
        let window = CustomWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )
        
        windowController = CustomWindowController(window: window)
        windowController?.contentViewController = NSHostingController(rootView: ContentView())
        
        // 确保窗口位置正确设置
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        
        // 延迟显示窗口，确保位置已经设置好
        DispatchQueue.main.async {
            self.windowController?.showWindow(nil)
        }
        
        // 关闭默认的 SwiftUI 窗口
        NSApp.windows.first { $0 != window }?.close()
        
        // 激活应用程序
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        isAppRunning = false
    }
    
    // 支持从 Dock 右键菜单关闭
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // 处理 Dock 菜单
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        
        let quitItem = NSMenuItem(title: "退出 Floating Clock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        
        return menu
    }
}

// 时间格式化器单例，避免重复创建
class TimeFormatter {
    static let shared = TimeFormatter()
    private let formatter: DateFormatter
    
    private init() {
        formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
    }
    
    func string(from date: Date) -> String {
        let baseTime = formatter.string(from: date)
        let milliseconds = Int((date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1000)
        return "\(baseTime).\(String(format: "%03d", milliseconds))"
    }
}

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var isDragging = false
    // 每 0.1 秒更新 3 次，即每 0.033 秒更新一次
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    
    // 使用常量避免重复创建
    private let textPadding = EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
    private let frameSize = CGSize(width: 220, height: 50)
    private let cornerRadius: CGFloat = 15
    private let shadowRadius: CGFloat = 8
    private let shadowOffset = CGPoint(x: 0, y: 2)
    
    // 预定义渐变颜色，避免重复创建
    private let gradientColors = [
        Color(red: 1.0, green: 0.71, blue: 0.76),  // 浅粉色
        Color.white,
        Color(red: 1.0, green: 0.71, blue: 0.76)   // 浅粉色
    ]
    
    private let strokeColors = [
        Color(red: 1.0, green: 0.5, blue: 0.65),  // 深粉色
        Color.white,
        Color(red: 1.0, green: 0.5, blue: 0.65)   // 深粉色
    ]
    
    var body: some View {
        Text(TimeFormatter.shared.string(from: currentTime))
            .font(.system(size: 24, weight: .medium, design: .monospaced))
            .foregroundColor(.black)
            .padding(textPadding)
            .frame(width: frameSize.width, height: frameSize.height)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: gradientColors[0], location: 0),
                                .init(color: gradientColors[1], location: 0.5),
                                .init(color: gradientColors[2], location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .strokeBorder(
                        LinearGradient(
                            colors: strokeColors,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(
                color: gradientColors[0].opacity(0.3),
                radius: shadowRadius,
                x: shadowOffset.x,
                y: shadowOffset.y
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                        }
                        NSApp.windows.first?.setFrameOrigin(
                            NSPoint(
                                x: value.location.x - value.startLocation.x + (NSApp.windows.first?.frame.origin.x ?? 0),
                                y: value.location.y - value.startLocation.y + (NSApp.windows.first?.frame.origin.y ?? 0)
                            )
                        )
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onTapGesture(count: 2) {
                NSApp.terminate(nil)
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .onAppear {
                // 确保窗口保持在最前面
                DispatchQueue.main.async {
                    NSApp.windows.first?.level = .floating
                }
            }
    }
}

@main
struct FloatingClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
} 