import SwiftUI
import WebKit
import Combine

// ─────────────────────────────────────────────────
// MARK: - MODELS
// ─────────────────────────────────────────────────

enum AppType: String, CaseIterable, Identifiable {
    case terminal, notepad, browser, calculator, explorer, settings, paint, clock
    var id: String { rawValue }

    var title: String {
        switch self {
        case .terminal: return "Terminal"
        case .notepad:  return "Notepad"
        case .browser:  return "Browser"
        case .calculator: return "Calculator"
        case .explorer: return "File Explorer"
        case .settings: return "Settings"
        case .paint:    return "Paint"
        case .clock:    return "World Clock"
        }
    }

    var icon: String {
        switch self {
        case .terminal:    return "terminal.fill"
        case .notepad:     return "doc.text.fill"
        case .browser:     return "globe"
        case .calculator:  return "function"
        case .explorer:    return "folder.fill"
        case .settings:    return "gearshape.2.fill"
        case .paint:       return "paintbrush.pointed.fill"
        case .clock:       return "clock.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .terminal:    return Color(hex: "22c55e")
        case .notepad:     return Color(hex: "3b82f6")
        case .browser:     return Color(hex: "0ea5e9")
        case .calculator:  return Color(hex: "f97316")
        case .explorer:    return Color(hex: "eab308")
        case .settings:    return Color(hex: "8b5cf6")
        case .paint:       return Color(hex: "ec4899")
        case .clock:       return Color(hex: "14b8a6")
        }
    }
}

struct WindowModel: Identifiable {
    let id = UUID()
    var type: AppType
    var position: CGPoint
    var size: CGSize
    var isMinimized: Bool = false
    var isMaximized: Bool = false
    var zIndex: Double = 1
    var urlString: String = "https://www.apple.com"
    var notepadText: String = ""
}

struct DesktopShortcut: Identifiable {
    let id = UUID()
    var type: AppType
    var position: CGPoint
}

struct OSNotification: Identifiable {
    let id = UUID()
    var message: String
    var icon: String
    var color: Color
    var timestamp: Date = Date()
}

struct FileItem: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var isDirectory: Bool
    var size: String
    var modified: String
}

// ─────────────────────────────────────────────────
// MARK: - COLOR EXTENSION
// ─────────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// ─────────────────────────────────────────────────
// MARK: - WALLPAPER MODEL
// ─────────────────────────────────────────────────

struct Wallpaper: Identifiable {
    let id: Int
    let name: String
    let colors: [Color]
    let start: UnitPoint
    let end: UnitPoint

    func gradient() -> LinearGradient {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
    }
}

let allWallpapers: [Wallpaper] = [
    Wallpaper(id: 0, name: "Deep Ocean",   colors: [Color(hex: "0f2027"), Color(hex: "203a43"), Color(hex: "2c5364")], start: .topLeading, end: .bottomTrailing),
    Wallpaper(id: 1, name: "Midnight",     colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")], start: .topLeading, end: .bottomTrailing),
    Wallpaper(id: 2, name: "Aurora",       colors: [Color(hex: "2d1b69"), Color(hex: "11998e"), Color(hex: "38ef7d")], start: .topLeading, end: .bottomTrailing),
    Wallpaper(id: 3, name: "Graphite",     colors: [Color(hex: "232526"), Color(hex: "414345")],                       start: .top,        end: .bottom),
    Wallpaper(id: 4, name: "Crimson",      colors: [Color(hex: "c94b4b"), Color(hex: "4b134f")],                       start: .topLeading, end: .bottomTrailing),
    Wallpaper(id: 5, name: "Royal",        colors: [Color(hex: "005c97"), Color(hex: "363795")],                       start: .top,        end: .bottom),
]

// ─────────────────────────────────────────────────
// MARK: - APP STATE
// ─────────────────────────────────────────────────

class OSState: ObservableObject {
    @Published var windows: [WindowModel] = []
    @Published var isStartMenuOpen = false
    @Published var isBSOD = false
    @Published var wallpaperIndex = 0
    @Published var notifications: [OSNotification] = []
    @Published var showNotificationPanel = false
    @Published var brightness: Double = 0.8
    @Published var volume: Double = 0.5
    @Published var isNightMode = false
    @Published var searchQuery = ""

    let wallpapers: [Wallpaper] = allWallpapers

    func openApp(_ type: AppType) {
        if let idx = windows.firstIndex(where: { $0.type == type }) {
            windows[idx].isMinimized = false
            bringToFront(id: windows[idx].id)
        } else {
            let w = WindowModel(
                type: type,
                position: CGPoint(x: 120 + Double(windows.count % 6) * 28, y: 80 + Double(windows.count % 6) * 28),
                size: defaultSize(type)
            )
            windows.append(w)
            bringToFront(id: w.id)
        }
        pushNotif(message: "\(type.title) opened", icon: type.icon, color: type.accentColor)
        isStartMenuOpen = false
    }

    func closeApp(id: UUID) {
        windows.removeAll { $0.id == id }
    }

    func bringToFront(id: UUID) {
        let maxZ = windows.map(\.zIndex).max() ?? 1
        if let idx = windows.firstIndex(where: { $0.id == id }) {
            windows[idx].zIndex = maxZ + 1
        }
    }

    func defaultSize(_ type: AppType) -> CGSize {
        switch type {
        case .calculator: return CGSize(width: 300, height: 420)
        case .browser:    return CGSize(width: 640, height: 480)
        case .paint:      return CGSize(width: 580, height: 460)
        default:          return CGSize(width: 480, height: 400)
        }
    }

    func pushNotif(message: String, icon: String, color: Color) {
        let n = OSNotification(message: message, icon: icon, color: color)
        withAnimation(.spring()) { notifications.insert(n, at: 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { self.notifications.removeAll { $0.id == n.id } }
        }
    }

    func triggerBSOD() {
        isStartMenuOpen = false
        withAnimation { isBSOD = true }
        windows.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation { self.isBSOD = false }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - ROOT CONTENT VIEW
// ─────────────────────────────────────────────────

struct ContentView: View {
    @StateObject var os = OSState()
    @State private var showBoot = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if showBoot {
                    BootScreen()
                        .transition(.opacity)
                        .zIndex(9999)
                } else if os.isBSOD {
                    BSODView()
                        .transition(.opacity)
                        .zIndex(9998)
                } else {
                    DesktopView()
                        .environmentObject(os)
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.5)) { showBoot = false }
            }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - BOOT SCREEN
// ─────────────────────────────────────────────────

struct BootScreen: View {
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3, 0.3, 0.3]
    @State private var logoScale: Double = 0.6
    @State private var logoOpacity: Double = 0

    let timer = Timer.publish(every: 0.22, on: .main, in: .common).autoconnect()
    @State private var dotIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(.white)
                    Text("NovOS")
                        .font(.system(size: 36, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(6)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                }

                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(dotOpacity[i])
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotOpacity = dotOpacity.enumerated().map { i, _ in i == dotIndex ? 1.0 : 0.25 }
            }
            dotIndex = (dotIndex + 1) % 5
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - BSOD VIEW
// ─────────────────────────────────────────────────

struct BSODView: View {
    @State private var progress: Double = 0
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(hex: "0050ef").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 28) {
                Text(":(")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your PC ran into a problem and needs to restart.")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("We're just collecting some error info, and then we'll restart for you.")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.75))
                }
                HStack(alignment: .center, spacing: 16) {
                    Text("\(Int(progress))% complete")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(.white)
                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(maxWidth: 200)
                }
                Text("Stop code: CRITICAL_PROCESS_DIED")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(50)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .onReceive(timer) { _ in
            if progress < 100 { progress += 1 }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - DESKTOP VIEW
// ─────────────────────────────────────────────────

struct DesktopView: View {
    @EnvironmentObject var os: OSState

    let desktopIcons: [(type: AppType, label: String)] = [
        (.explorer, "My PC"), (.browser, "Browser"), (.notepad, "Notepad"),
        (.paint, "Paint"), (.clock, "World Clock")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Wallpaper
            os.wallpapers[os.wallpaperIndex].gradient()
                .ignoresSafeArea()

            // Subtle grid dots
            Canvas { ctx, size in
                for x in stride(from: 0, to: size.width, by: 32) {
                    for y in stride(from: 0, to: size.height, by: 32) {
                        let r = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                        ctx.fill(Path(ellipseIn: r), with: .color(.white.opacity(0.06)))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Night mode overlay
            if os.isNightMode {
                Color.orange.opacity(0.08).ignoresSafeArea().allowsHitTesting(false)
            }

            // Desktop icon column
            VStack(alignment: .leading, spacing: 6) {
                ForEach(desktopIcons, id: \.type) { item in
                    DesktopIconView(type: item.type, label: item.label)
                }
            }
            .padding(.top, 20)
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Windows
            ForEach(os.windows.sorted(by: { $0.zIndex < $1.zIndex })) { win in
                if !win.isMinimized {
                    WindowFrame(window: win)
                        .zIndex(win.zIndex)
                }
            }

            // Notifications toast
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(os.notifications.prefix(3)) { notif in
                    NotificationToast(notif: notif)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 12)
            .padding(.trailing, 12)
            .allowsHitTesting(false)

            // Start Menu overlay
            if os.isStartMenuOpen {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring()) { os.isStartMenuOpen = false } }
                StartMenuView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
            }

            // Notification panel
            if os.showNotificationPanel {
                NotificationPanel()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(998)
            }

            // Taskbar
            TaskbarView()
                .zIndex(997)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                os.isStartMenuOpen = false
                os.showNotificationPanel = false
            }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - DESKTOP ICON
// ─────────────────────────────────────────────────

struct DesktopIconView: View {
    @EnvironmentObject var os: OSState
    let type: AppType
    let label: String
    @State private var pressed = false

    var body: some View {
        Button {
            os.openApp(type)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(width: 54, height: 54)
                        .shadow(color: type.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    Image(systemName: type.icon)
                        .font(.system(size: 26))
                        .foregroundColor(type.accentColor)
                }
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.25), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded { _ in pressed = false })
    }
}

// ─────────────────────────────────────────────────
// MARK: - WINDOW FRAME
// ─────────────────────────────────────────────────

struct WindowFrame: View {
    @EnvironmentObject var os: OSState
    var window: WindowModel

    @State private var dragOffset: CGSize = .zero
    @State private var currentPosition: CGPoint = .zero
    @State private var isDragging = false

    private var isFocused: Bool {
        os.windows.max(by: { $0.zIndex < $1.zIndex })?.id == window.id
    }

    var body: some View {
        let w = window.isMaximized ? UIScreen.main.bounds.width : window.size.width
        let h = window.isMaximized ? UIScreen.main.bounds.height - 48 : window.size.height
        let pos = window.isMaximized
            ? CGPoint(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height - 48) / 2)
            : CGPoint(x: window.position.x + window.size.width / 2 + dragOffset.width,
                      y: window.position.y + window.size.height / 2 + dragOffset.height)

        ZStack {
            RoundedRectangle(cornerRadius: window.isMaximized ? 0 : 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: window.isMaximized ? 0 : 12)
                        .stroke(isFocused ? window.type.accentColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0.25), radius: isFocused ? 24 : 10, x: 0, y: 8)

            VStack(spacing: 0) {
                // Title bar
                WindowTitleBar(window: window, isFocused: isFocused)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                if !window.isMaximized {
                                    isDragging = true
                                    dragOffset = v.translation
                                }
                            }
                            .onEnded { v in
                                if !window.isMaximized {
                                    isDragging = false
                                    if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                                        os.windows[idx].position.x += v.translation.width
                                        os.windows[idx].position.y += v.translation.height
                                    }
                                    dragOffset = .zero
                                }
                            }
                    )

                Divider().opacity(0.2)

                // App content
                Group {
                    switch window.type {
                    case .terminal:    TerminalView()
                    case .notepad:     NotepadView(window: window)
                    case .browser:     BrowserView(window: window)
                    case .calculator:  CalculatorView()
                    case .explorer:    ExplorerView()
                    case .settings:    SettingsView()
                    case .paint:       PaintView()
                    case .clock:       WorldClockView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: window.isMaximized ? 0 : 12))
        .position(pos)
        .onTapGesture { os.bringToFront(id: window.id) }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: window.isMaximized)
    }
}

// ─────────────────────────────────────────────────
// MARK: - WINDOW TITLE BAR
// ─────────────────────────────────────────────────

struct WindowTitleBar: View {
    @EnvironmentObject var os: OSState
    let window: WindowModel
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Traffic lights
            Group {
                // Close
                Circle()
                    .fill(Color(hex: "ff5f57"))
                    .frame(width: 14, height: 14)
                    .overlay(Image(systemName: "xmark").font(.system(size: 6, weight: .bold)).opacity(isFocused ? 1 : 0))
                    .onTapGesture { withAnimation(.spring()) { os.closeApp(id: window.id) } }

                // Minimize
                Circle()
                    .fill(Color(hex: "febc2e"))
                    .frame(width: 14, height: 14)
                    .overlay(Image(systemName: "minus").font(.system(size: 6, weight: .bold)).opacity(isFocused ? 1 : 0))
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                                os.windows[idx].isMinimized = true
                            }
                        }
                    }

                // Maximize
                Circle()
                    .fill(Color(hex: "28c840"))
                    .frame(width: 14, height: 14)
                    .overlay(Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 5, weight: .bold)).opacity(isFocused ? 1 : 0))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                                os.windows[idx].isMaximized.toggle()
                            }
                        }
                    }
            }
            .padding(.leading, 4)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: window.type.icon)
                    .font(.system(size: 11))
                    .foregroundColor(window.type.accentColor)
                Text(window.type.title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isFocused ? .primary : .secondary)

            Spacer()
            Spacer().frame(width: 56) // balance
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(isFocused ? Color.primary.opacity(0.05) : Color.clear)
    }
}

// ─────────────────────────────────────────────────
// MARK: - TASKBAR
// ─────────────────────────────────────────────────

struct TaskbarView: View {
    @EnvironmentObject var os: OSState
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var focusedWindowId: UUID? {
        os.windows.max(by: { $0.zIndex < $1.zIndex })?.id
    }

    var body: some View {
        HStack(spacing: 0) {
            // Start button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    os.isStartMenuOpen.toggle()
                    os.showNotificationPanel = false
                }
            } label: {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(os.isStartMenuOpen ? .white : .white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(os.isStartMenuOpen ? Color(hex: "0078d4") : Color.clear)
                    .cornerRadius(8)
            }
            .padding(.leading, 4)

            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 6)

            // Open windows
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(os.windows) { win in
                        TaskbarWindowButton(win: win, isFocused: focusedWindowId == win.id) {
                            if win.isMinimized {
                                withAnimation(.spring()) {
                                    if let idx = os.windows.firstIndex(where: { $0.id == win.id }) {
                                        os.windows[idx].isMinimized = false
                                    }
                                }
                                os.bringToFront(id: win.id)
                            } else if focusedWindowId == win.id {
                                withAnimation(.spring()) {
                                    if let idx = os.windows.firstIndex(where: { $0.id == win.id }) {
                                        os.windows[idx].isMinimized = true
                                    }
                                }
                            } else {
                                os.bringToFront(id: win.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            Spacer()

            // System tray
            HStack(spacing: 2) {
                // Night mode toggle
                Button {
                    withAnimation { os.isNightMode.toggle() }
                } label: {
                    Image(systemName: os.isNightMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 13))
                        .foregroundColor(os.isNightMode ? .orange : .yellow)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }

                // Notification bell
                Button {
                    withAnimation(.spring()) {
                        os.showNotificationPanel.toggle()
                        os.isStartMenuOpen = false
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(os.showNotificationPanel ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                            .cornerRadius(6)
                        if os.notifications.count > 0 {
                            Circle()
                                .fill(Color(hex: "ef4444"))
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }

                // Clock
                VStack(alignment: .trailing, spacing: 1) {
                    Text(currentTime.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(currentTime.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .frame(minWidth: 60)
            }
        }
        .frame(height: 48)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(.white.opacity(0.12)), alignment: .top)
        .onReceive(timer) { t in currentTime = t }
    }
}

struct TaskbarWindowButton: View {
    let win: WindowModel
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: win.type.icon)
                    .font(.system(size: 12))
                    .foregroundColor(win.type.accentColor)
                Text(win.type.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(win.isMinimized ? 0.5 : 0.9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(isFocused && !win.isMinimized ? win.type.accentColor.opacity(0.25) : Color.white.opacity(0.08))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocused && !win.isMinimized ? win.type.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────
// MARK: - START MENU
// ─────────────────────────────────────────────────

struct StartMenuView: View {
    @EnvironmentObject var os: OSState
    @State private var query = ""

    let allApps: [AppType] = AppType.allCases
    var filtered: [AppType] {
        query.isEmpty ? allApps : allApps.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps...", text: $query)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(10)
            .padding(16)

            // Pinned apps grid
            if query.isEmpty {
                Text("PINNED")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(filtered) { type in
                        StartMenuAppButton(type: type)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            } else {
                // Search results
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(filtered) { type in
                            Button { os.openApp(type) } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(type.accentColor.opacity(0.2))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: type.icon)
                                            .foregroundColor(type.accentColor)
                                    }
                                    Text(type.title)
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 200)
            }

            Divider().opacity(0.15).padding(.horizontal, 12)

            // Footer
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "0078d4"), Color(hex: "005a9e")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Admin")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Local Account")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Button { os.openApp(.settings) } label: {
                        Image(systemName: "gearshape.fill")
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    Button { os.triggerBSOD() } label: {
                        Image(systemName: "power")
                            .foregroundColor(Color(hex: "ef4444"))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "ef4444").opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 32, x: 0, y: -8)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 12)
        .allowsHitTesting(true)
        .onTapGesture { } // Prevent propagation
    }
}

struct StartMenuAppButton: View {
    @EnvironmentObject var os: OSState
    let type: AppType
    @State private var pressed = false

    var body: some View {
        Button { os.openApp(type) } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(type.accentColor.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(type.accentColor)
                }
                Text(type.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.9 : 1)
        .animation(.spring(response: 0.2), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded { _ in pressed = false }
        )
    }
}

// ─────────────────────────────────────────────────
// MARK: - NOTIFICATION TOAST
// ─────────────────────────────────────────────────

struct NotificationToast: View {
    let notif: OSNotification

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(notif.color.opacity(0.2)).frame(width: 30, height: 30)
                Image(systemName: notif.icon).font(.system(size: 13)).foregroundColor(notif.color)
            }
            Text(notif.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 240)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
}

// ─────────────────────────────────────────────────
// MARK: - NOTIFICATION PANEL
// ─────────────────────────────────────────────────

struct NotificationPanel: View {
    @EnvironmentObject var os: OSState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notifications")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if !os.notifications.isEmpty {
                    Button("Clear All") {
                        withAnimation { os.notifications.removeAll() }
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "0078d4"))
                }
            }
            .padding(16)

            if os.notifications.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell.slash").font(.system(size: 28)).foregroundColor(.secondary)
                    Text("No notifications").font(.callout).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(os.notifications) { notif in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(notif.color.opacity(0.2)).frame(width: 34, height: 34)
                                    Image(systemName: notif.icon).font(.system(size: 14)).foregroundColor(notif.color)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(notif.message).font(.system(size: 13, weight: .medium))
                                    Text(notif.timestamp.formatted(.relative(presentation: .named)))
                                        .font(.system(size: 10)).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(10)
                        }
                    }
                    .padding(12)
                }
            }

            Divider().opacity(0.15)

            // Quick settings row
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK SETTINGS").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    QuickToggle(icon: "moon.fill", label: "Night Mode", isOn: $os.isNightMode, color: .orange)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Label("Brightness", systemImage: "sun.max.fill").font(.system(size: 11)).foregroundColor(.secondary)
                    Slider(value: $os.brightness, in: 0...1).accentColor(Color(hex: "0078d4"))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Label("Volume", systemImage: "speaker.wave.2.fill").font(.system(size: 11)).foregroundColor(.secondary)
                    Slider(value: $os.volume, in: 0...1).accentColor(Color(hex: "0078d4"))
                }
            }
            .padding(16)
        }
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.4), radius: 32, x: -8, y: 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.bottom, 56)
        .padding(.trailing, 8)
        .allowsHitTesting(true)
        .onTapGesture {}
    }
}

struct QuickToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Button { withAnimation { isOn.toggle() } } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? color.opacity(0.25) : Color.primary.opacity(0.07))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isOn ? color : .secondary)
                }
                Text(label).font(.system(size: 9)).foregroundColor(.secondary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: TERMINAL
// ─────────────────────────────────────────────────

struct TerminalView: View {
    @State private var lines: [String] = [
        "NovOS Terminal v2.0",
        "Copyright (c) 2025 NovOS Corp.",
        "",
        "Type 'help' for available commands.",
        ""
    ]
    @State private var input = ""
    @FocusState private var focused: Bool
    @State private var scrollId = UUID()

    let commands: [String: String] = [
        "help": "Available: help, clear, date, echo, whoami, ls, uname, uptime",
        "whoami": "admin",
        "uname": "NovOS 2.0.0 ARM64",
        "ls": "Applications/  Documents/  Downloads/  Desktop/",
        "date": "",
        "uptime": "up 3 days, 4:22, 1 user",
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(lines.indices, id: \.self) { i in
                            Text(lines[i])
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(i == 0 || i == 1 ? Color(hex: "22c55e") : .green.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text("").id(scrollId)
                    }
                    .padding(12)
                }
                .onChange(of: lines.count) { _ in
                    withAnimation { proxy.scrollTo(scrollId) }
                }
            }
            Divider().background(Color.green.opacity(0.3))
            HStack(spacing: 8) {
                Text("admin@novos:~$")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "22c55e"))
                TextField("", text: $input)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.green)
                    .focused($focused)
                    .onSubmit { runCommand() }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "0d1117"))
        .onTapGesture { focused = true }
    }

    func runCommand() {
        let cmd = input.trimmingCharacters(in: .whitespaces).lowercased()
        lines.append("admin@novos:~$ \(input)")
        if cmd == "clear" {
            lines = [""]
        } else if cmd == "date" {
            lines.append(Date().formatted())
        } else if cmd.hasPrefix("echo ") {
            lines.append(String(cmd.dropFirst(5)))
        } else if let out = commands[cmd] {
            if !out.isEmpty { lines.append(out) }
        } else if !cmd.isEmpty {
            lines.append("zsh: command not found: \(cmd)")
        }
        lines.append("")
        input = ""
        scrollId = UUID()
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: NOTEPAD
// ─────────────────────────────────────────────────

struct NotepadView: View {
    let window: WindowModel
    @State private var text: String = "Welcome to Notepad\n\nStart typing..."
    @State private var wordCount = 0
    @State private var fontSize: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Text("Font size:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Button { fontSize = max(10, fontSize - 1) } label: {
                    Image(systemName: "minus").frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.07)).cornerRadius(4)
                }
                Text("\(Int(fontSize))").font(.system(size: 11, weight: .medium)).frame(width: 24)
                Button { fontSize = min(32, fontSize + 1) } label: {
                    Image(systemName: "plus").frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.07)).cornerRadius(4)
                }
                Spacer()
                Text("\(wordCount) words")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))

            Divider().opacity(0.15)

            TextEditor(text: $text)
                .font(.system(size: fontSize))
                .padding(12)
                .onChange(of: text) { val in
                    wordCount = val.split(separator: " ").count
                }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: BROWSER
// ─────────────────────────────────────────────────

struct BrowserView: View {
    let window: WindowModel
    @State private var urlString: String = "https://www.apple.com"
    @State private var committedURL: String = "https://www.apple.com"
    @State private var isLoading = false
    @State private var backStack: [String] = []
    @State private var canGoBack = false

    var body: some View {
        VStack(spacing: 0) {
            // Address bar
            HStack(spacing: 6) {
                Button {
                    if let last = backStack.popLast() {
                        committedURL = last
                        urlString = last
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(backStack.isEmpty ? 0.04 : 0.08))
                        .cornerRadius(6)
                }
                .disabled(backStack.isEmpty)
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: isLoading ? "xmark" : "lock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(isLoading ? .red : Color(hex: "22c55e"))
                    TextField("Search or enter URL", text: $urlString)
                        .font(.system(size: 12))
                        .onSubmit { navigate() }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(8)

                Button { navigate() } label: {
                    Image(systemName: "arrow.right")
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))

            if isLoading {
                ProgressView(value: 0.7).progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "0078d4"))).frame(height: 2).padding(0)
            }

            Divider().opacity(0.15)

            WebViewRepresentable(urlString: committedURL, isLoading: $isLoading)
        }
    }

    func navigate() {
        var raw = urlString.trimmingCharacters(in: .whitespaces)
        if !raw.contains(".") || raw.contains(" ") {
            raw = "https://www.google.com/search?q=\(raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? raw)"
        } else if !raw.hasPrefix("http") {
            raw = "https://\(raw)"
        }
        backStack.append(committedURL)
        committedURL = raw
        urlString = raw
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.navigationDelegate = context.coordinator
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString), uiView.url?.absoluteString != urlString {
            uiView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        init(_ p: WebViewRepresentable) { parent = p }
        func webView(_ wv: WKWebView, didStartProvisionalNavigation _: WKNavigation!) { parent.isLoading = true }
        func webView(_ wv: WKWebView, didFinish _: WKNavigation!) { parent.isLoading = false }
        func webView(_ wv: WKWebView, didFail _: WKNavigation!, withError _: Error) { parent.isLoading = false }
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: CALCULATOR
// ─────────────────────────────────────────────────

struct CalculatorView: View {
    @State private var display = "0"
    @State private var accumulated: Double = 0
    @State private var op: String? = nil
    @State private var typing = false
    @State private var expression = ""
    @State private var justEvaluated = false

    let rows: [[CalcBtn]] = [
        [.fn("AC"), .fn("±"), .fn("%"), .op("/")],
        [.num("7"), .num("8"), .num("9"), .op("×")],
        [.num("4"), .num("5"), .num("6"), .op("−")],
        [.num("1"), .num("2"), .num("3"), .op("+")],
    ]

    enum CalcBtn: Hashable {
        case num(String), fn(String), op(String), eq(String), zero(String), dot(String)
        var label: String {
            switch self { case .num(let s), .fn(let s), .op(let s), .eq(let s), .zero(let s), .dot(let s): return s }
        }
        var bg: Color {
            switch self {
            case .op: return Color(hex: "f97316")
            case .eq: return Color(hex: "f97316")
            case .fn: return Color(hex: "6b7280")
            default:  return Color(hex: "374151")
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            // Expression
            if !expression.isEmpty {
                Text(expression)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            // Display
            Text(display)
                .font(.system(size: display.count > 9 ? 28 : 48, weight: .thin, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            // Buttons
            VStack(spacing: 10) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { btn in
                            Button { press(btn) } label: {
                                Text(btn.label)
                                    .font(.system(size: 22, weight: .regular, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(btn.bg)
                                    .cornerRadius(50)
                            }
                            .frame(minWidth: 64, maxWidth: .infinity, minHeight: 64, maxHeight: 64)
                        }
                    }
                }
                // Bottom row: wide zero + dot + equals
                HStack(spacing: 10) {
                    Button { press(.zero("0")) } label: {
                        Text("0")
                            .font(.system(size: 22, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(CalcBtn.zero("0").bg)
                            .cornerRadius(50)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 64)

                    Button { press(.dot(".")) } label: {
                        Text(".")
                            .font(.system(size: 22, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(CalcBtn.dot(".").bg)
                            .cornerRadius(50)
                    }
                    .frame(minWidth: 64, maxWidth: .infinity, minHeight: 64, maxHeight: 64)

                    Button { press(.eq("=")) } label: {
                        Text("=")
                            .font(.system(size: 22, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(CalcBtn.eq("=").bg)
                            .cornerRadius(50)
                    }
                    .frame(minWidth: 64, maxWidth: .infinity, minHeight: 64, maxHeight: 64)
                }
            }
            .padding(14)
        }
        .background(Color(hex: "1c1c1e"))
    }

    func press(_ btn: CalcBtn) {
        let label = btn.label
        switch btn {
        case .num(let d):
            if justEvaluated { display = d; expression = ""; justEvaluated = false; typing = true; return }
            display = (typing && display != "0") ? display + d : d
            typing = true
        case .dot:
            if !display.contains(".") { display += "."; typing = true }
        case .fn(let f):
            switch f {
            case "AC": display = "0"; accumulated = 0; op = nil; typing = false; expression = ""; justEvaluated = false
            case "±": display = display.hasPrefix("-") ? String(display.dropFirst()) : "-" + display
            case "%": display = format((Double(display) ?? 0) / 100)
            default: break
            }
        case .op(let o):
            let sym = o == "/" ? "/" : o
            expression = "\(display) \(sym)"
            accumulated = Double(display) ?? 0
            op = o
            typing = false
            justEvaluated = false
        case .eq:
            if let o = op {
                let cur = Double(display) ?? 0
                var result: Double = 0
                switch o {
                case "+": result = accumulated + cur
                case "−": result = accumulated - cur
                case "×": result = accumulated * cur
                case "/": result = cur != 0 ? accumulated / cur : 0
                default: break
                }
                expression = "\(format(accumulated)) \(o) \(display) ="
                display = format(result)
                accumulated = result
                op = nil
                typing = false
                justEvaluated = true
            }
        case .zero:
            if typing { display += "0" } else { display = "0"; typing = true }
        }
    }

    func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(v)
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: FILE EXPLORER
// ─────────────────────────────────────────────────

struct ExplorerView: View {
    @State private var selectedItem: UUID? = nil
    @State private var currentPath = "My PC"
    @State private var viewMode: ViewMode = .list
    @State private var sortBy: SortOption = .name

    enum ViewMode { case list, grid }
    enum SortOption: String, CaseIterable { case name = "Name", size = "Size", modified = "Date Modified" }

    let sidebarItems: [(icon: String, name: String, color: Color)] = [
        ("desktopcomputer", "Desktop", .blue),
        ("doc.fill", "Documents", .yellow),
        ("arrow.down.circle.fill", "Downloads", .green),
        ("photo.fill", "Images", .purple),
        ("music.note", "Music", .pink),
        ("internaldrive.fill", "System (C:)", .gray),
    ]

    let files: [FileItem] = [
        FileItem(name: "System32", icon: "folder.fill", isDirectory: true, size: "—", modified: "Today"),
        FileItem(name: "Users", icon: "folder.fill", isDirectory: true, size: "—", modified: "Yesterday"),
        FileItem(name: "Program Files", icon: "folder.fill", isDirectory: true, size: "—", modified: "Jan 12"),
        FileItem(name: "README.txt", icon: "doc.text.fill", isDirectory: false, size: "4 KB", modified: "Today"),
        FileItem(name: "setup.exe", icon: "gearshape.fill", isDirectory: false, size: "128 KB", modified: "Feb 1"),
        FileItem(name: "photo.jpg", icon: "photo.fill", isDirectory: false, size: "3.2 MB", modified: "Jan 28"),
        FileItem(name: "audio.mp3", icon: "music.note", isDirectory: false, size: "6.8 MB", modified: "Jan 20"),
        FileItem(name: "archive.zip", icon: "archivebox.fill", isDirectory: false, size: "22 MB", modified: "Jan 15"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                Text("FAVORITES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                ForEach(sidebarItems, id: \.name) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon).font(.system(size: 14)).foregroundColor(item.color)
                        Text(item.name).font(.system(size: 13)).lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(item.name == "Desktop" ? Color.primary.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                    .padding(.horizontal, 4)
                }
                Spacer()
            }
            .frame(width: 150)
            .background(Color.primary.opacity(0.04))

            Divider().opacity(0.15)

            // Main content
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: 8) {
                    Text(currentPath)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("Sort", selection: $sortBy) {
                        ForEach(SortOption.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 11))
                    HStack(spacing: 4) {
                        Button { viewMode = .list } label: {
                            Image(systemName: "list.bullet")
                                .padding(5)
                                .background(viewMode == .list ? Color.primary.opacity(0.12) : Color.clear)
                                .cornerRadius(5)
                        }
                        Button { viewMode = .grid } label: {
                            Image(systemName: "square.grid.2x2")
                                .padding(5)
                                .background(viewMode == .grid ? Color.primary.opacity(0.12) : Color.clear)
                                .cornerRadius(5)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.02))

                Divider().opacity(0.12)

                if viewMode == .list {
                    // Header
                    HStack {
                        Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Size").frame(width: 70, alignment: .trailing)
                        Text("Modified").frame(width: 90, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.03))

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(files) { file in
                                HStack(spacing: 8) {
                                    Image(systemName: file.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(file.isDirectory ? Color(hex: "eab308") : .secondary)
                                        .frame(width: 20)
                                    Text(file.name)
                                        .font(.system(size: 13))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(file.size)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .frame(width: 70, alignment: .trailing)
                                    Text(file.modified)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .frame(width: 90, alignment: .trailing)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selectedItem == file.id ? Color.primary.opacity(0.1) : Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedItem = file.id }
                            }
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(files) { file in
                                VStack(spacing: 6) {
                                    Image(systemName: file.icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(file.isDirectory ? Color(hex: "eab308") : .secondary)
                                        .frame(width: 48, height: 48)
                                        .background(selectedItem == file.id ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
                                        .cornerRadius(8)
                                    Text(file.name)
                                        .font(.system(size: 10))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .onTapGesture { selectedItem = file.id }
                            }
                        }
                        .padding(12)
                    }
                }

                // Status bar
                Divider().opacity(0.12)
                HStack {
                    Text("\(files.count) items")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    if selectedItem != nil {
                        Text("· 1 selected")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("C:\\")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.02))
            }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: SETTINGS
// ─────────────────────────────────────────────────

struct SettingsView: View {
    @EnvironmentObject var os: OSState
    @State private var selected = "Personalization"

    let sections = ["Personalization", "System", "About"]

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings").font(.system(size: 16, weight: .semibold)).padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
                ForEach(sections, id: \.self) { s in
                    Button { selected = s } label: {
                        Text(s)
                            .font(.system(size: 13))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(selected == s ? Color.primary.opacity(0.12) : Color.clear)
                            .cornerRadius(6)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 160)
            .background(Color.primary.opacity(0.04))

            Divider().opacity(0.15)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selected {
                    case "Personalization":
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Wallpaper").font(.headline)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(os.wallpapers) { wp in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(wp.gradient())
                                            .frame(height: 60)
                                        if os.wallpaperIndex == wp.id {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "0078d4"), lineWidth: 2.5)
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "0078d4"))
                                                .background(Circle().fill(.white).padding(2))
                                        }
                                    }
                                    .overlay(
                                        Text(wp.name)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 5),
                                        alignment: .bottom
                                    )
                                    .onTapGesture { withAnimation { os.wallpaperIndex = wp.id } }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Display").font(.headline)
                            HStack {
                                Label("Night Mode", systemImage: "moon.fill").font(.system(size: 13))
                                Spacer()
                                Toggle("", isOn: $os.isNightMode).labelsHidden()
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                        }

                    case "System":
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Sound & Display").font(.headline)
                            VStack(spacing: 12) {
                                SettingsSlider(label: "Volume", icon: "speaker.wave.2.fill", value: $os.volume)
                                SettingsSlider(label: "Brightness", icon: "sun.max.fill", value: $os.brightness)
                            }
                        }

                    case "About":
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About NovOS").font(.headline)
                            InfoRow(label: "OS Version", value: "NovOS 2.0.0")
                            InfoRow(label: "Build", value: "2025.02.19")
                            InfoRow(label: "Architecture", value: "ARM64")
                            InfoRow(label: "Device", value: UIDevice.current.model)
                            InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                        }

                    default: EmptyView()
                    }
                }
                .padding(20)
            }
        }
    }
}

struct SettingsSlider: View {
    let label: String
    let icon: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 20).foregroundColor(.secondary)
            Text(label).font(.system(size: 13)).frame(width: 80, alignment: .leading)
            Slider(value: $value, in: 0...1).accentColor(Color(hex: "0078d4"))
            Text("\(Int(value * 100))%").font(.system(size: 11)).foregroundColor(.secondary).frame(width: 36, alignment: .trailing)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium))
        }
        .padding(12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: PAINT
// ─────────────────────────────────────────────────

struct PaintView: View {
    @State private var lines: [DrawnLine] = []
    @State private var currentLine: DrawnLine? = nil
    @State private var selectedColor: Color = .red
    @State private var brushSize: CGFloat = 4
    @State private var tool: DrawTool = .pen

    enum DrawTool: String, CaseIterable { case pen = "pencil", eraser = "eraser" }

    struct DrawnLine: Identifiable {
        let id = UUID()
        var points: [CGPoint]
        var color: Color
        var width: CGFloat
    }

    let palette: [Color] = [.black, .white, Color(hex: "ef4444"), Color(hex: "f97316"), Color(hex: "eab308"), Color(hex: "22c55e"), Color(hex: "3b82f6"), Color(hex: "8b5cf6"), Color(hex: "ec4899"), Color(hex: "14b8a6"), .brown, .gray]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Tools
                HStack(spacing: 4) {
                    ForEach(DrawTool.allCases, id: \.self) { t in
                        Button { tool = t } label: {
                            Image(systemName: t.rawValue)
                                .padding(6)
                                .background(tool == t ? Color.primary.opacity(0.15) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().frame(height: 20)

                // Brush size
                HStack(spacing: 6) {
                    Text("Size").font(.system(size: 11)).foregroundColor(.secondary)
                    Slider(value: $brushSize, in: 1...20).frame(width: 80).accentColor(selectedColor)
                    Text("\(Int(brushSize))px").font(.system(size: 10)).foregroundColor(.secondary).frame(width: 28)
                }

                Divider().frame(height: 20)

                // Palette
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(palette, id: \.self) { c in
                            Circle()
                                .fill(c)
                                .frame(width: 22, height: 22)
                                .overlay(Circle().stroke(selectedColor == c ? Color.white : Color.clear, lineWidth: 2.5))
                                .shadow(radius: selectedColor == c ? 3 : 0)
                                .onTapGesture { selectedColor = c; tool = .pen }
                        }
                    }
                }

                Spacer()

                Button { lines.removeAll() } label: {
                    Label("Clear", systemImage: "trash").font(.system(size: 11)).padding(.horizontal, 8).padding(.vertical, 5).background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04))

            Divider().opacity(0.15)

            // Canvas
            GeometryReader { geo in
                ZStack {
                    Color.white
                    Canvas { ctx, _ in
                        for line in lines {
                            drawLine(ctx: ctx, line: line)
                        }
                        if let cur = currentLine {
                            drawLine(ctx: ctx, line: cur)
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let pt = val.location
                            guard pt.x >= 0, pt.y >= 0, pt.x <= geo.size.width, pt.y <= geo.size.height else { return }
                            if currentLine == nil {
                                currentLine = DrawnLine(points: [pt], color: tool == .eraser ? .white : selectedColor, width: tool == .eraser ? brushSize * 3 : brushSize)
                            } else {
                                currentLine?.points.append(pt)
                            }
                        }
                        .onEnded { _ in
                            if let line = currentLine { lines.append(line) }
                            currentLine = nil
                        }
                )
            }
        }
    }

    func drawLine(ctx: GraphicsContext, line: DrawnLine) {
        guard line.points.count > 1 else { return }
        var path = Path()
        path.move(to: line.points[0])
        for pt in line.points.dropFirst() { path.addLine(to: pt) }
        ctx.stroke(path, with: .color(line.color), style: StrokeStyle(lineWidth: line.width, lineCap: .round, lineJoin: .round))
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: WORLD CLOCK
// ─────────────────────────────────────────────────

struct WorldClockView: View {
    @State private var time = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let zones: [(city: String, id: String, flag: String)] = [
        ("New York",  "America/New_York",    "🇺🇸"),
        ("London",    "Europe/London",        "🇬🇧"),
        ("Paris",     "Europe/Paris",         "🇫🇷"),
        ("Dubai",     "Asia/Dubai",           "🇦🇪"),
        ("Tokyo",     "Asia/Tokyo",           "🇯🇵"),
        ("Sydney",    "Australia/Sydney",     "🇦🇺"),
        ("Local",     TimeZone.current.identifier, "🏠"),
    ]

    func timeIn(_ id: String) -> String {
        let tz = TimeZone(identifier: id) ?? .current
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.timeZone = tz
        return fmt.string(from: time)
    }

    func offsetLabel(_ id: String) -> String {
        let tz = TimeZone(identifier: id) ?? .current
        let off = tz.secondsFromGMT() / 3600
        return off >= 0 ? "UTC+\(off)" : "UTC\(off)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Analog clock for local time
            ClockFaceView(time: time)
                .frame(height: 140)
                .padding(.vertical, 12)

            Divider().opacity(0.15)

            // World clocks list
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(zones, id: \.id) { zone in
                        HStack {
                            Text(zone.flag).font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(zone.city).font(.system(size: 13, weight: .medium))
                                Text(offsetLabel(zone.id)).font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(timeIn(zone.id))
                                .font(.system(size: 18, weight: .light, design: .rounded))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(8)
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .onReceive(timer) { t in time = t }
    }
}

struct ClockFaceView: View {
    let time: Date
    var calendar: Calendar { .current }
    var seconds: Double { Double(calendar.component(.second, from: time)) }
    var minutes: Double { Double(calendar.component(.minute, from: time)) + seconds / 60 }
    var hours: Double { Double(calendar.component(.hour, from: time) % 12) + minutes / 60 }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let r = size / 2
            ZStack {
                // Face
                Circle().fill(Color.primary.opacity(0.05))
                Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1.5)

                // Hour ticks
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 1.5, height: r * 0.1)
                        .offset(y: -(r - r * 0.06))
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                // Hour hand
                ClockHand(color: .primary, width: 4, length: r * 0.5, angle: hours * 30 - 90)
                // Minute hand
                ClockHand(color: .primary, width: 2.5, length: r * 0.7, angle: minutes * 6 - 90)
                // Second hand
                ClockHand(color: Color(hex: "ef4444"), width: 1, length: r * 0.78, angle: seconds * 6 - 90)
                // Center dot
                Circle().fill(Color(hex: "ef4444")).frame(width: 8, height: 8)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

struct ClockHand: View {
    let color: Color
    let width: CGFloat
    let length: CGFloat
    let angle: Double

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .cornerRadius(width / 2)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }
}

// ─────────────────────────────────────────────────
// MARK: - PREVIEW
// ─────────────────────────────────────────────────

#Preview {
    ContentView()
}
