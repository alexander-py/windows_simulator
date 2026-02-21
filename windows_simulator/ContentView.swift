import SwiftUI
import WebKit
import Combine

// ─────────────────────────────────────────────────
// MARK: - DESIGN SYSTEM
// ─────────────────────────────────────────────────

struct DS {
    // Core palette
    static let bg0          = Color(hex: "08090a")   // deepest background
    static let bg1          = Color(hex: "0e1012")   // surface
    static let bg2          = Color(hex: "161a1d")   // elevated surface
    static let bg3          = Color(hex: "1e2328")   // hover / selection
    static let stroke       = Color(hex: "ffffff", alpha: 0.07)
    static let strokeBright = Color(hex: "ffffff", alpha: 0.14)
    static let textPrimary  = Color(hex: "e8eaed")
    static let textSecond   = Color(hex: "8b9099")
    static let textTertiary = Color(hex: "555c65")
    static let accent       = Color(hex: "5e7ce2")   // periwinkle-blue
    static let accentGlow   = Color(hex: "5e7ce2", alpha: 0.35)
    static let danger       = Color(hex: "e25e5e")
    static let success      = Color(hex: "5ee2a0")
    static let warning      = Color(hex: "e2b35e")

    // Corner radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 20

    // Shadows
    static func shadowMd(_ color: Color = .black) -> some ViewModifier {
        ShadowModifier(color: color.opacity(0.4), radius: 16, x: 0, y: 8)
    }
    static func shadowLg(_ color: Color = .black) -> some ViewModifier {
        ShadowModifier(color: color.opacity(0.6), radius: 40, x: 0, y: 20)
    }

    static let monoFont = Font.system(.body, design: .monospaced)
}

struct ShadowModifier: ViewModifier {
    let color: Color; let radius: CGFloat; let x: CGFloat; let y: CGFloat
    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// Glass card style
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = DS.radiusMd
    var strokeOpacity: Double = 1.0
    func body(content: Content) -> some View {
        content
            .background(DS.bg2.opacity(0.85))
            .background(.ultraThinMaterial.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DS.stroke.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = DS.radiusMd, strokeOpacity: Double = 1.0) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }
}

// ─────────────────────────────────────────────────
// MARK: - MODELS
// ─────────────────────────────────────────────────

enum AppType: String, CaseIterable, Identifiable {
    case terminal, notepad, browser, calculator, explorer, settings, paint, clock
    var id: String { rawValue }

    var title: String {
        switch self {
        case .terminal:   return "Terminal"
        case .notepad:    return "Notepad"
        case .browser:    return "Browser"
        case .calculator: return "Calculator"
        case .explorer:   return "Files"
        case .settings:   return "Settings"
        case .paint:      return "Paint"
        case .clock:      return "World Clock"
        }
    }

    var icon: String {
        switch self {
        case .terminal:   return "terminal.fill"
        case .notepad:    return "doc.text.fill"
        case .browser:    return "safari.fill"
        case .calculator: return "equal.square.fill"
        case .explorer:   return "folder.fill"
        case .settings:   return "slider.horizontal.3"
        case .paint:      return "paintpalette.fill"
        case .clock:      return "globe"
        }
    }

    var accent: Color {
        switch self {
        case .terminal:   return Color(hex: "5ee2a0")
        case .notepad:    return Color(hex: "5e9ee2")
        case .browser:    return Color(hex: "5ec2e2")
        case .calculator: return Color(hex: "e2945e")
        case .explorer:   return Color(hex: "e2cc5e")
        case .settings:   return Color(hex: "a05ee2")
        case .paint:      return Color(hex: "e25ea0")
        case .clock:      return Color(hex: "5ee2cc")
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.9), accent.opacity(0.5)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

struct WindowModel: Identifiable {
    let id = UUID()
    var type: AppType
    var position: CGPoint
    var size: CGSize
    var isMinimized = false
    var isMaximized = false
    var zIndex: Double = 1
    var title: String { type.title }
}

struct OSNotification: Identifiable {
    let id = UUID()
    var message: String
    var subtitle: String
    var icon: String
    var color: Color
    var timestamp = Date()
}

struct FileItem: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var isDirectory: Bool
    var size: String
    var modified: String
    var color: Color
}

// ─────────────────────────────────────────────────
// MARK: - COLOR EXTENSION
// ─────────────────────────────────────────────────

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }
}

// ─────────────────────────────────────────────────
// MARK: - WALLPAPERS
// ─────────────────────────────────────────────────

struct Wallpaper: Identifiable {
    let id: Int
    let name: String
    let colors: [Color]

    func gradient() -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

let allWallpapers: [Wallpaper] = [
    Wallpaper(id: 0, name: "Void",      colors: [Color(hex: "08090a"), Color(hex: "0e1320"), Color(hex: "0a0e18")]),
    Wallpaper(id: 1, name: "Aurora",    colors: [Color(hex: "0d0d1a"), Color(hex: "0d2038"), Color(hex: "0d3828")]),
    Wallpaper(id: 2, name: "Nebula",    colors: [Color(hex: "130d1a"), Color(hex: "200d38"), Color(hex: "0d1a30")]),
    Wallpaper(id: 3, name: "Ember",     colors: [Color(hex: "1a0d0d"), Color(hex: "381a0d"), Color(hex: "200d0d")]),
    Wallpaper(id: 4, name: "Arctic",    colors: [Color(hex: "0d1520"), Color(hex: "0d2535"), Color(hex: "0d3050")]),
    Wallpaper(id: 5, name: "Graphite",  colors: [Color(hex: "0e0e10"), Color(hex: "181820"), Color(hex: "101015")]),
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
    @Published var brightness: Double = 0.85
    @Published var volume: Double = 0.6
    @Published var isNightMode = false
    @Published var activeContextMenu: UUID? = nil

    let wallpapers = allWallpapers

    func openApp(_ type: AppType) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            if let idx = windows.firstIndex(where: { $0.type == type }) {
                windows[idx].isMinimized = false
                bringToFront(id: windows[idx].id)
            } else {
                let count = windows.count
                let w = WindowModel(
                    type: type,
                    position: CGPoint(x: 110 + Double(count % 7) * 32, y: 60 + Double(count % 7) * 32),
                    size: defaultSize(type)
                )
                windows.append(w)
                bringToFront(id: w.id)
            }
        }
        pushNotif(title: type.title, subtitle: "App launched", icon: type.icon, color: type.accent)
        isStartMenuOpen = false
    }

    func closeApp(id: UUID) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            windows.removeAll { $0.id == id }
        }
    }

    func bringToFront(id: UUID) {
        let maxZ = windows.map(\.zIndex).max() ?? 1
        if let idx = windows.firstIndex(where: { $0.id == id }) {
            windows[idx].zIndex = maxZ + 1
        }
    }

    func defaultSize(_ type: AppType) -> CGSize {
        switch type {
        case .calculator: return CGSize(width: 320, height: 500)
        case .browser:    return CGSize(width: 700, height: 520)
        case .paint:      return CGSize(width: 620, height: 500)
        case .clock:      return CGSize(width: 400, height: 480)
        default:          return CGSize(width: 520, height: 420)
        }
    }

    func pushNotif(title: String, subtitle: String, icon: String, color: Color) {
        let n = OSNotification(message: title, subtitle: subtitle, icon: icon, color: color)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            notifications.insert(n, at: 0)
            if notifications.count > 30 { notifications = Array(notifications.prefix(30)) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeOut(duration: 0.3)) { self.notifications.removeAll { $0.id == n.id } }
        }
    }

    func triggerBSOD() {
        isStartMenuOpen = false
        withAnimation(.easeIn(duration: 0.2)) { isBSOD = true }
        windows.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeOut) { self.isBSOD = false }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - CONTENT VIEW
// ─────────────────────────────────────────────────

struct ContentView: View {
    @StateObject var os = OSState()
    @State private var showBoot = true

    var body: some View {
        GeometryReader { _ in
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
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                withAnimation(.easeOut(duration: 0.6)) { showBoot = false }
            }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - BOOT SCREEN
// ─────────────────────────────────────────────────

struct BootScreen: View {
    @State private var progress: CGFloat = 0
    @State private var logoOpacity: Double = 0
    @State private var logoY: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var barOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "08090a").ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color(hex: "5e7ce2", alpha: 0.08), .clear],
                center: .center, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(DS.accent.opacity(0.15), lineWidth: 1)
                            .frame(width: 90, height: 90)
                        Circle()
                            .stroke(DS.accent.opacity(0.08), lineWidth: 1)
                            .frame(width: 110, height: 110)

                        // Icon container
                        Circle()
                            .fill(DS.bg2)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle().stroke(DS.strokeBright, lineWidth: 1)
                            )

                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(DS.accent.gradient)
                    }

                    VStack(spacing: 6) {
                        Text("WindOS")
                            .font(.system(size: 32, weight: .thin, design: .rounded))
                            .tracking(10)
                            .foregroundColor(DS.textPrimary)

                        Text("Version 3.0")
                            .font(.system(size: 11, weight: .regular))
                            .tracking(3)
                            .foregroundColor(DS.textTertiary)
                            .opacity(subtitleOpacity)
                    }
                }
                .opacity(logoOpacity)
                .offset(y: logoY)

                Spacer()

                // Progress
                VStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DS.bg3)
                            .frame(width: 200, height: 2)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DS.accent)
                            .frame(width: 200 * progress, height: 2)
                            .shadow(color: DS.accentGlow, radius: 6)
                    }
                    .opacity(barOpacity)

                    Text("Starting up...")
                        .font(.system(size: 10, weight: .regular))
                        .tracking(2)
                        .foregroundColor(DS.textTertiary)
                        .opacity(barOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
                logoOpacity = 1; logoY = 0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
                barOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.5).delay(1.1)) {
                progress = 1
            }
        }
    }
}

// ─────────────────────────────────────────────────
// MARK: - BSOD
// ─────────────────────────────────────────────────

struct BSODView: View {
    @State private var progress: Double = 0
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(hex: "0050ef").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 32) {
                Text(":(")
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Your PC ran into a problem\nand needs to restart.")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white)
                        .lineSpacing(4)

                    Text("We're collecting some error info, and then we'll restart for you.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("\(Int(progress))% complete")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.2)).frame(width: 280, height: 3)
                        RoundedRectangle(cornerRadius: 2).fill(.white).frame(width: 280 * progress / 100, height: 3)
                    }
                }

                Text("Stop code: CRITICAL_PROCESS_DIED\nWhat failed: ntoskrnl.exe")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(4)
            }
            .padding(60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .onReceive(timer) { _ in if progress < 100 { progress = min(100, progress + 1.1) } }
    }
}

// ─────────────────────────────────────────────────
// MARK: - DESKTOP
// ─────────────────────────────────────────────────

struct DesktopView: View {
    @EnvironmentObject var os: OSState

    let dockApps: [AppType] = [.explorer, .browser, .terminal, .notepad, .calculator, .paint, .clock, .settings]
    let desktopIcons: [(type: AppType, label: String)] = [
        (.explorer, "My Files"), (.browser, "Browser"), (.notepad, "Notepad"), (.paint, "Paint")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Wallpaper
            os.wallpapers[os.wallpaperIndex].gradient()
                .ignoresSafeArea()

            // Noise texture overlay
            Canvas { ctx, size in
                for x in stride(from: 0.0, to: size.width, by: 2.5) {
                    for y in stride(from: 0.0, to: size.height, by: 2.5) {
                        let opacity = Double.random(in: 0...0.025)
                        ctx.fill(Path(CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(.white.opacity(opacity)))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Night mode
            if os.isNightMode {
                Color.orange.opacity(0.06).ignoresSafeArea().allowsHitTesting(false)
                LinearGradient(colors: [Color.clear, Color.orange.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea().allowsHitTesting(false)
            }

            // Desktop icons
            VStack(alignment: .leading, spacing: 8) {
                ForEach(desktopIcons, id: \.type) { item in
                    DesktopIconView(type: item.type, label: item.label)
                }
            }
            .padding(.top, 24)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Windows
            ForEach(os.windows.sorted(by: { $0.zIndex < $1.zIndex })) { win in
                if !win.isMinimized {
                    WindowFrame(window: win)
                        .zIndex(win.zIndex)
                }
            }

            // Notification toasts (top-right)
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(os.notifications.prefix(3)) { n in
                    NotificationToast(notif: n)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 14)
            .padding(.trailing, 14)
            .allowsHitTesting(false)

            // Start menu overlay
            if os.isStartMenuOpen {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { os.isStartMenuOpen = false } }
                StartMenuView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.97, anchor: .bottom)),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(999)
            }

            // Notification panel
            if os.showNotificationPanel {
                NotificationPanel()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .zIndex(998)
            }

            // Taskbar
            TaskbarView()
                .zIndex(1000)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
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
    @State private var hovered = false
    @State private var pressed = false

    var body: some View {
        Button { os.openApp(type) } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusMd)
                        .fill(DS.bg2.opacity(hovered ? 0.95 : 0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radiusMd)
                                .stroke(hovered ? type.accent.opacity(0.5) : DS.stroke, lineWidth: 1)
                        )
                        .shadow(color: hovered ? type.accent.opacity(0.3) : .clear, radius: 12, y: 4)
                        .frame(width: 52, height: 52)

                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(type.gradient)
                }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DS.textPrimary.opacity(0.9))
                    .shadow(color: .black.opacity(0.9), radius: 3, y: 1)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.92 : (hovered ? 1.04 : 1.0))
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: pressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .onHover { hovered = $0 }
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded   { _ in pressed = false }
        )
    }
}

// ─────────────────────────────────────────────────
// MARK: - WINDOW FRAME
// ─────────────────────────────────────────────────

struct WindowFrame: View {
    @EnvironmentObject var os: OSState
    var window: WindowModel

    @State private var dragOffset: CGSize = .zero
    @State private var resizeOffset: CGSize = .zero

    private var isFocused: Bool {
        os.windows.max(by: { $0.zIndex < $1.zIndex })?.id == window.id
    }

    private var w: CGFloat {
        window.isMaximized ? UIScreen.main.bounds.width : window.size.width
    }
    private var h: CGFloat {
        window.isMaximized ? UIScreen.main.bounds.height - 52 : window.size.height
    }
    private var pos: CGPoint {
        if window.isMaximized {
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height - 52) / 2)
        }
        return CGPoint(
            x: window.position.x + window.size.width / 2 + dragOffset.width,
            y: window.position.y + window.size.height / 2 + dragOffset.height
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Window shell
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: window.isMaximized ? 0 : DS.radiusLg)
                    .fill(DS.bg1.opacity(0.97))

                // Glass tint
                RoundedRectangle(cornerRadius: window.isMaximized ? 0 : DS.radiusLg)
                    .fill(.ultraThinMaterial.opacity(0.12))

                // Border
                RoundedRectangle(cornerRadius: window.isMaximized ? 0 : DS.radiusLg)
                    .stroke(
                        isFocused
                            ? LinearGradient(colors: [window.type.accent.opacity(0.5), window.type.accent.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [DS.stroke, DS.stroke], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )

                VStack(spacing: 0) {
                    WindowTitleBar(window: window, isFocused: isFocused)
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    if !window.isMaximized { dragOffset = v.translation }
                                }
                                .onEnded { v in
                                    if !window.isMaximized {
                                        if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                                            os.windows[idx].position.x += v.translation.width
                                            os.windows[idx].position.y += v.translation.height
                                        }
                                        dragOffset = .zero
                                    }
                                }
                        )

                    Divider()
                        .background(isFocused ? window.type.accent.opacity(0.3) : DS.stroke)

                    // App content
                    Group {
                        switch window.type {
                        case .terminal:   TerminalView()
                        case .notepad:    NotepadView(window: window)
                        case .browser:    BrowserView(window: window)
                        case .calculator: CalculatorView()
                        case .explorer:   ExplorerView()
                        case .settings:   SettingsView()
                        case .paint:      PaintView()
                        case .clock:      WorldClockView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .shadow(
                color: isFocused ? window.type.accent.opacity(0.15) : .black.opacity(0.5),
                radius: isFocused ? 40 : 20, x: 0, y: isFocused ? 16 : 8
            )

            // Resize handle
            if !window.isMaximized {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9))
                    .foregroundColor(DS.textTertiary)
                    .padding(6)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                                    os.windows[idx].size.width = max(280, window.size.width + v.translation.width)
                                    os.windows[idx].size.height = max(200, window.size.height + v.translation.height)
                                }
                            }
                    )
            }
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: window.isMaximized ? 0 : DS.radiusLg))
        .position(pos)
        .onTapGesture { os.bringToFront(id: window.id) }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: window.isMaximized)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: window.size)
    }
}

// ─────────────────────────────────────────────────
// MARK: - TITLE BAR
// ─────────────────────────────────────────────────

struct WindowTitleBar: View {
    @EnvironmentObject var os: OSState
    let window: WindowModel
    let isFocused: Bool
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            // Traffic lights
            HStack(spacing: 7) {
                TrafficLight(color: Color(hex: "ff5f57"), hovered: hovering) {
                    os.closeApp(id: window.id)
                } label: { Image(systemName: "xmark").font(.system(size: 5.5, weight: .black)) }

                TrafficLight(color: Color(hex: "febc2e"), hovered: hovering) {
                    if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                        os.windows[idx].isMinimized = true
                    }
                } label: { Image(systemName: "minus").font(.system(size: 5.5, weight: .black)) }

                TrafficLight(color: Color(hex: "28c840"), hovered: hovering) {
                    if let idx = os.windows.firstIndex(where: { $0.id == window.id }) {
                        os.windows[idx].isMaximized.toggle()
                    }
                } label: { Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 4.5, weight: .black)) }
            }
            .padding(.leading, 14)
            .onHover { hovering = $0 }

            Spacer()

            // Title
            HStack(spacing: 6) {
                Image(systemName: window.type.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(window.type.gradient)
                Text(window.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isFocused ? DS.textPrimary : DS.textTertiary)
            }

            Spacer()
            Spacer().frame(width: 70) // balance
        }
        .frame(height: 40)
        .background(
            isFocused
                ? window.type.accent.opacity(0.04)
                : Color.clear
        )
    }
}

struct TrafficLight<L: View>: View {
    let color: Color
    let hovered: Bool
    let action: () -> Void
    @ViewBuilder let label: L
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(.black.opacity(0.1), lineWidth: 0.5))
                label
                    .foregroundColor(.black.opacity(hovered ? 0.65 : 0))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.88 : 1.0)
        .animation(.spring(response: 0.15), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded   { _ in pressed = false }
        )
    }
}

// ─────────────────────────────────────────────────
// MARK: - TASKBAR
// ─────────────────────────────────────────────────

struct TaskbarView: View {
    @EnvironmentObject var os: OSState
    @State private var time = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var focusedId: UUID? { os.windows.max(by: { $0.zIndex < $1.zIndex })?.id }

    var body: some View {
        HStack(spacing: 0) {
            // Start / Logo button
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    os.isStartMenuOpen.toggle()
                    os.showNotificationPanel = false
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusSm)
                        .fill(os.isStartMenuOpen ? DS.accent.opacity(0.25) : DS.bg3.opacity(0.6))
                        .frame(width: 38, height: 38)
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(os.isStartMenuOpen ? DS.accent : DS.textSecond)
                }
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
            .padding(.trailing, 6)

            // Separator
            Rectangle()
                .fill(DS.stroke)
                .frame(width: 1, height: 22)
                .padding(.trailing, 8)

            // Open windows
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(os.windows) { win in
                        TaskbarWindowChip(win: win, isFocused: focusedId == win.id) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if win.isMinimized {
                                    if let idx = os.windows.firstIndex(where: { $0.id == win.id }) {
                                        os.windows[idx].isMinimized = false
                                    }
                                    os.bringToFront(id: win.id)
                                } else if focusedId == win.id {
                                    if let idx = os.windows.firstIndex(where: { $0.id == win.id }) {
                                        os.windows[idx].isMinimized = true
                                    }
                                } else {
                                    os.bringToFront(id: win.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            Spacer()

            // System tray
            HStack(spacing: 4) {
                // Night mode
                TrayButton(icon: os.isNightMode ? "moon.fill" : "sun.max.fill",
                           color: os.isNightMode ? DS.warning : DS.warning.opacity(0.6),
                           active: os.isNightMode) {
                    withAnimation { os.isNightMode.toggle() }
                }

                // Notifications
                TrayButton(icon: "bell.fill",
                           color: DS.accent,
                           active: os.showNotificationPanel,
                           badge: os.notifications.count > 0 ? "\(os.notifications.count)" : nil) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        os.showNotificationPanel.toggle()
                        os.isStartMenuOpen = false
                    }
                }

                // Clock
                VStack(alignment: .trailing, spacing: 1) {
                    Text(time.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                    Text(time.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 10))
                        .foregroundColor(DS.textTertiary)
                }
                .padding(.horizontal, 10)
                .frame(minWidth: 62)
            }
            .padding(.trailing, 4)
        }
        .frame(height: 52)
        .background(DS.bg1.opacity(0.96))
        .background(.ultraThinMaterial.opacity(0.2))
        .overlay(Rectangle().fill(DS.stroke).frame(height: 1), alignment: .top)
        .onReceive(timer) { t in time = t }
    }
}

struct TrayButton: View {
    let icon: String
    let color: Color
    let active: Bool
    var badge: String? = nil
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: DS.radiusSm)
                    .fill(active ? color.opacity(0.18) : (hovered ? DS.bg3 : .clear))
                    .frame(width: 34, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusSm)
                            .stroke(active ? color.opacity(0.4) : Color.clear, lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(active ? color : DS.textSecond)
                    .frame(width: 34, height: 34)

                if let b = badge {
                    ZStack {
                        Circle()
                            .fill(DS.danger)
                            .frame(width: 14, height: 14)
                        Text(b)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

struct TaskbarWindowChip: View {
    let win: WindowModel
    let isFocused: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: win.type.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isFocused && !win.isMinimized ? AnyShapeStyle(win.type.gradient) : AnyShapeStyle(DS.textSecond))
                Text(win.type.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(win.isMinimized ? DS.textTertiary : DS.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusSm)
                    .fill(isFocused && !win.isMinimized ? win.type.accent.opacity(0.18) : (hovered ? DS.bg3 : DS.bg2.opacity(0.5)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusSm)
                    .stroke(isFocused && !win.isMinimized ? win.type.accent.opacity(0.4) : DS.stroke.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.15), value: hovered)
    }
}

// ─────────────────────────────────────────────────
// MARK: - START MENU
// ─────────────────────────────────────────────────

struct StartMenuView: View {
    @EnvironmentObject var os: OSState
    @State private var query = ""
    @State private var appeared = false

    let allApps: [AppType] = AppType.allCases
    var filtered: [AppType] {
        query.isEmpty ? allApps : allApps.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Apps")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textTertiary)
                TextField("Search apps...", text: $query)
                    .font(.system(size: 13))
                    .foregroundColor(DS.textPrimary)
                    .tint(DS.accent)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DS.textTertiary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(DS.bg3)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
            .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.stroke))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            if query.isEmpty {
                // Grid
                Text("PINNED")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(DS.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(Array(filtered.enumerated()), id: \.element) { i, type in
                        StartMenuAppTile(type: type)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(i) * 0.04), value: appeared)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(filtered) { type in
                            SearchResultRow(type: type)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
            }

            Divider().background(DS.stroke).padding(.horizontal, 12)

            // Footer
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [DS.accent, DS.accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Admin")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DS.textPrimary)
                        Text("Local Account")
                            .font(.system(size: 10))
                            .foregroundColor(DS.textTertiary)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    FooterButton(icon: "gearshape.fill", color: DS.textSecond) { os.openApp(.settings) }
                    FooterButton(icon: "power", color: DS.danger) { os.triggerBSOD() }
                }
            }
            .padding(16)
        }
        .frame(width: 400)
        .background(DS.bg1.opacity(0.97))
        .background(.ultraThinMaterial.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusXl))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusXl)
                .stroke(DS.strokeBright, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 50, x: 0, y: -10)
        .padding(.bottom, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 10)
        .allowsHitTesting(true)
        .onTapGesture {}
        .onAppear { withAnimation { appeared = true } }
    }
}

struct StartMenuAppTile: View {
    @EnvironmentObject var os: OSState
    let type: AppType
    @State private var hovered = false
    @State private var pressed = false

    var body: some View {
        Button { os.openApp(type) } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusMd)
                        .fill(hovered ? type.accent.opacity(0.18) : DS.bg2)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radiusMd)
                                .stroke(hovered ? type.accent.opacity(0.4) : DS.stroke)
                        )
                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(type.gradient)
                }
                Text(type.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(hovered ? DS.textPrimary : DS.textSecond)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
        .onHover { hovered = $0 }
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded   { _ in pressed = false }
        )
    }
}

struct SearchResultRow: View {
    @EnvironmentObject var os: OSState
    let type: AppType
    @State private var hovered = false

    var body: some View {
        Button { os.openApp(type) } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusSm)
                        .fill(type.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: type.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(type.gradient)
                }
                Text(type.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
                    .foregroundColor(DS.textTertiary)
                    .opacity(hovered ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(hovered ? DS.bg3 : DS.bg2.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.15), value: hovered)
    }
}

struct FooterButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(hovered ? color : DS.textSecond)
                .frame(width: 34, height: 34)
                .background(hovered ? color.opacity(0.12) : DS.bg3)
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusSm)
                        .stroke(DS.stroke)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.15), value: hovered)
    }
}

// ─────────────────────────────────────────────────
// MARK: - NOTIFICATIONS
// ─────────────────────────────────────────────────

struct NotificationToast: View {
    let notif: OSNotification

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(notif.color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: notif.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(notif.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(notif.message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                Text(notif.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(DS.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: 260)
        .background(DS.bg2.opacity(0.95))
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusMd)
                .stroke(DS.strokeBright, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95, anchor: .trailing)),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
}

struct NotificationPanel: View {
    @EnvironmentObject var os: OSState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                Spacer()
                if !os.notifications.isEmpty {
                    Button("Clear All") {
                        withAnimation(.easeOut(duration: 0.25)) { os.notifications.removeAll() }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DS.accent)
                    .buttonStyle(.plain)
                }
            }
            .padding(16)

            Divider().background(DS.stroke)

            if os.notifications.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 26))
                        .foregroundColor(DS.textTertiary)
                    Text("No notifications")
                        .font(.system(size: 13))
                        .foregroundColor(DS.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(os.notifications) { notif in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(notif.color.opacity(0.15)).frame(width: 34, height: 34)
                                    Image(systemName: notif.icon).font(.system(size: 13, weight: .semibold)).foregroundColor(notif.color)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(notif.message).font(.system(size: 12, weight: .semibold)).foregroundColor(DS.textPrimary)
                                    Text(notif.timestamp.formatted(.relative(presentation: .named)))
                                        .font(.system(size: 10)).foregroundColor(DS.textTertiary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(DS.bg3)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 260)
            }

            Divider().background(DS.stroke)

            // Quick settings
            VStack(alignment: .leading, spacing: 14) {
                Text("QUICK SETTINGS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(DS.textTertiary)

                HStack(spacing: 8) {
                    QuickToggle(icon: "moon.fill", label: "Night Mode", isOn: $os.isNightMode, color: DS.warning)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "sun.max.fill").font(.system(size: 11)).foregroundColor(DS.textTertiary)
                        Text("Brightness").font(.system(size: 11)).foregroundColor(DS.textTertiary)
                        Spacer()
                        Text("\(Int(os.brightness * 100))%").font(.system(size: 10)).foregroundColor(DS.textTertiary)
                    }
                    CustomSlider(value: $os.brightness, color: DS.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 11)).foregroundColor(DS.textTertiary)
                        Text("Volume").font(.system(size: 11)).foregroundColor(DS.textTertiary)
                        Spacer()
                        Text("\(Int(os.volume * 100))%").font(.system(size: 10)).foregroundColor(DS.textTertiary)
                    }
                    CustomSlider(value: $os.volume, color: DS.accent)
                }
            }
            .padding(16)
        }
        .frame(width: 300)
        .background(DS.bg1.opacity(0.97))
        .background(.ultraThinMaterial.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusXl))
        .overlay(RoundedRectangle(cornerRadius: DS.radiusXl).stroke(DS.strokeBright, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 40, x: -8, y: 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.bottom, 60)
        .padding(.trailing, 8)
        .allowsHitTesting(true)
        .onTapGesture {}
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(DS.bg3)
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * value, height: 4)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in value = max(0, min(1, v.location.x / geo.size.width)) }
            )
        }
        .frame(height: 4)
    }
}

struct QuickToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Button { withAnimation(.spring(response: 0.3)) { isOn.toggle() } } label: {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusSm)
                        .fill(isOn ? color.opacity(0.2) : DS.bg3)
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radiusSm)
                                .stroke(isOn ? color.opacity(0.4) : DS.stroke)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isOn ? color : DS.textTertiary)
                }
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(isOn ? DS.textPrimary : DS.textTertiary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: TERMINAL
// ─────────────────────────────────────────────────

struct TerminalView: View {
    @State private var lines: [(text: String, type: LineType)] = [
        ("WindOS Terminal v3.0", .system),
        ("Copyright (c) 2025 WindOS Corp. All rights reserved.", .system),
        ("", .system),
        ("Type 'help' for a list of commands.", .dim),
        ("", .dim),
    ]
    @State private var input = ""
    @FocusState private var focused: Bool
    @State private var scrollAnchor = UUID()

    enum LineType { case system, output, error, dim, command }

    let commands: [String: String] = [
        "help":   "help · clear · date · echo <text> · whoami · ls · uname · uptime · sysinfo",
        "whoami": "admin",
        "uname":  "WindOS 3.0.0 ARM64 Darwin-Hybrid",
        "ls":     "Applications/  Documents/  Downloads/  Desktop/  Library/",
        "date":   "",
        "uptime": "up 3 days, 14:22, 1 user, load averages: 0.42 0.31 0.28",
        "sysinfo":"Model: WindOS Virtual Machine | RAM: 8 GB | CPU: WindOS A3 Chip | Disk: 256 GB",
    ]

    func lineColor(_ t: LineType) -> Color {
        switch t {
        case .system:  return DS.success
        case .output:  return DS.textPrimary.opacity(0.85)
        case .error:   return DS.danger
        case .dim:     return DS.textTertiary
        case .command: return DS.accent
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(lines.indices, id: \.self) { i in
                            Text(lines[i].text)
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(lineColor(lines[i].type))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        Text("").id(scrollAnchor)
                    }
                    .padding(14)
                }
                .onChange(of: lines.count) { _ in
                    withAnimation { proxy.scrollTo(scrollAnchor) }
                }
            }

            // Input row
            HStack(spacing: 8) {
                Text("❯").font(.system(size: 13, design: .monospaced)).foregroundColor(DS.success)
                Text("admin").font(.system(size: 12, design: .monospaced)).foregroundColor(DS.accent)
                Text("~$").font(.system(size: 12, design: .monospaced)).foregroundColor(DS.textTertiary)
                TextField("", text: $input)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundColor(DS.textPrimary)
                    .tint(DS.success)
                    .focused($focused)
                    .onSubmit { runCommand() }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DS.bg2.opacity(0.5))
            .overlay(Rectangle().fill(DS.stroke).frame(height: 1), alignment: .top)
        }
        .background(Color(hex: "090d0f"))
        .onTapGesture { focused = true }
    }

    func runCommand() {
        let raw = input
        let cmd = raw.trimmingCharacters(in: .whitespaces).lowercased()
        lines.append(("❯ admin ~$ \(raw)", .command))

        if cmd == "clear" {
            lines = [("", .dim)]
        } else if cmd == "date" {
            lines.append((Date().formatted(), .output))
        } else if cmd.hasPrefix("echo ") {
            lines.append((String(raw.dropFirst(5)), .output))
        } else if let out = commands[cmd] {
            if !out.isEmpty { lines.append((out, .output)) }
        } else if !cmd.isEmpty {
            lines.append(("zsh: command not found: \(cmd)", .error))
        }
        lines.append(("", .dim))
        input = ""
        scrollAnchor = UUID()
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: NOTEPAD
// ─────────────────────────────────────────────────

struct NotepadView: View {
    let window: WindowModel
    @State private var text = "# Welcome to Notepad\n\nStart typing your thoughts here...\n\nTips:\n- Use the toolbar to adjust font size\n- Your work is preserved between sessions"
    @State private var fontSize: CGFloat = 14
    @State private var wordCount = 0
    @State private var charCount = 0

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 14) {
                Text("Aa")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DS.textTertiary)

                HStack(spacing: 4) {
                    ToolbarIconButton(icon: "minus") { fontSize = max(10, fontSize - 1) }
                    Text("\(Int(fontSize))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DS.textSecond)
                        .frame(width: 28)
                    ToolbarIconButton(icon: "plus") { fontSize = min(36, fontSize + 1) }
                }

                Rectangle().fill(DS.stroke).frame(width: 1, height: 16)

                Spacer()

                HStack(spacing: 10) {
                    StatBadge(label: "\(wordCount) words")
                    StatBadge(label: "\(charCount) chars")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DS.bg2.opacity(0.6))

            Divider().background(DS.stroke)

            TextEditor(text: $text)
                .font(.system(size: fontSize))
                .foregroundColor(DS.textPrimary)
                .scrollContentBackground(.hidden)
                .background(DS.bg1.opacity(0.3))
                .padding(14)
                .onChange(of: text) { val in
                    wordCount = val.split(whereSeparator: \.isWhitespace).count
                    charCount = val.count
                }
        }
        .onAppear {
            wordCount = text.split(whereSeparator: \.isWhitespace).count
            charCount = text.count
        }
    }
}

struct ToolbarIconButton: View {
    let icon: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(hovered ? DS.textPrimary : DS.textTertiary)
                .frame(width: 24, height: 24)
                .background(hovered ? DS.bg3 : DS.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(DS.stroke))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

struct StatBadge: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(DS.textTertiary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(DS.bg3)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: BROWSER
// ─────────────────────────────────────────────────

struct BrowserView: View {
    let window: WindowModel
    @State private var urlString = "https://www.apple.com"
    @State private var committedURL = "https://www.apple.com"
    @State private var isLoading = false
    @State private var backStack: [String] = []
    @State private var loadProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Address bar
            HStack(spacing: 8) {
                // Nav buttons
                HStack(spacing: 4) {
                    NavButton(icon: "chevron.left", enabled: !backStack.isEmpty) {
                        if let last = backStack.popLast() { committedURL = last; urlString = last }
                    }
                    NavButton(icon: "arrow.clockwise", enabled: true) {
                        committedURL = urlString
                    }
                }

                // URL bar
                HStack(spacing: 8) {
                    Image(systemName: isLoading ? "dot.radiowaves.left.and.right" : "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isLoading ? DS.warning : DS.success)
                        .frame(width: 16)

                    TextField("Search or enter URL", text: $urlString)
                        .font(.system(size: 12))
                        .foregroundColor(DS.textPrimary)
                        .tint(DS.accent)
                        .onSubmit { navigate() }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(DS.bg3)
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.stroke))

                NavButton(icon: "arrow.right", enabled: true) { navigate() }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(DS.bg2.opacity(0.7))

            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.clear).frame(height: 2)
                if isLoading {
                    Rectangle()
                        .fill(DS.accent)
                        .frame(width: .infinity, height: 2)
                        .shadow(color: DS.accentGlow, radius: 4)
                        .transition(.opacity)
                }
            }

            Divider().background(DS.stroke)

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

struct NavButton: View {
    let icon: String
    let enabled: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(enabled ? (hovered ? DS.textPrimary : DS.textSecond) : DS.textTertiary)
                .frame(width: 30, height: 30)
                .background(hovered && enabled ? DS.bg3 : DS.bg2.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.stroke))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { if enabled { hovered = $0 } }
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
    @State private var flashOp: String? = nil

    let rows: [[CalcBtn]] = [
        [.fn("AC"), .fn("±"), .fn("%"), .op("/")],
        [.num("7"), .num("8"), .num("9"), .op("×")],
        [.num("4"), .num("5"), .num("6"), .op("−")],
        [.num("1"), .num("2"), .num("3"), .op("+")],
    ]

    enum CalcBtn: Hashable {
        case num(String), fn(String), op(String), eq, zero, dot
        var label: String {
            switch self { case .num(let s), .fn(let s), .op(let s): return s; case .eq: return "="; case .zero: return "0"; case .dot: return "."; }
        }
    }

    func btnBG(_ btn: CalcBtn) -> Color {
        switch btn {
        case .op: return flashOp == btn.label ? DS.warning : DS.warning.opacity(0.18)
        case .eq: return DS.warning
        case .fn: return DS.bg3
        default:  return DS.bg2.opacity(0.8)
        }
    }
    func btnFG(_ btn: CalcBtn) -> Color {
        switch btn {
        case .op: return flashOp == btn.label ? .black : DS.warning
        case .eq: return .black
        case .fn: return DS.textSecond
        default:  return DS.textPrimary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Display area
            VStack(alignment: .trailing, spacing: 4) {
                Spacer()
                if !expression.isEmpty {
                    Text(expression)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(DS.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Text(display)
                    .font(.system(size: display.count > 9 ? 30 : 52, weight: .thin, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(height: 130)

            Divider().background(DS.stroke)

            // Button grid
            VStack(spacing: 8) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { btn in
                            CalcButton(label: btn.label, bg: btnBG(btn), fg: btnFG(btn)) {
                                press(btn)
                            }
                        }
                    }
                }
                // Bottom row
                HStack(spacing: 8) {
                    CalcButton(label: "0", bg: btnBG(.zero), fg: btnFG(.zero), wide: true) { press(.zero) }
                    CalcButton(label: ".", bg: btnBG(.dot),  fg: btnFG(.dot))  { press(.dot) }
                    CalcButton(label: "=", bg: DS.warning,    fg: .black)       { press(.eq) }
                }
            }
            .padding(14)
        }
        .background(Color(hex: "111214"))
    }

    func press(_ btn: CalcBtn) {
        withAnimation(.spring(response: 0.2)) {
            switch btn {
            case .num(let d):
                if justEvaluated { display = d; expression = ""; justEvaluated = false; typing = true; return }
                display = (typing && display != "0") ? display + d : d
                typing = true
            case .dot:
                if !display.contains(".") { display += "."; typing = true }
            case .fn(let f):
                switch f {
                case "AC": display = "0"; accumulated = 0; op = nil; typing = false; expression = ""; justEvaluated = false; flashOp = nil
                case "±": display = display.hasPrefix("-") ? String(display.dropFirst()) : "-" + display
                case "%": display = format((Double(display) ?? 0) / 100)
                default: break
                }
            case .op(let o):
                expression = "\(display) \(o)"
                accumulated = Double(display) ?? 0
                op = o; typing = false; justEvaluated = false; flashOp = o
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
                    accumulated = result; op = nil; typing = false; justEvaluated = true; flashOp = nil
                }
            case .zero:
                if typing { display += "0" } else { display = "0"; typing = true }
            }
        }
    }

    func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(v)
    }
}

struct CalcButton: View {
    let label: String
    let bg: Color
    let fg: Color
    var wide = false
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundColor(fg)
                .frame(maxWidth: wide ? .infinity : nil, maxHeight: .infinity)
                .frame(width: wide ? nil : nil, height: 64)
                .frame(minWidth: wide ? .infinity : 64)
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(DS.stroke.opacity(0.5))
                )
                .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: wide ? .infinity : nil)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.1)) { pressed = true } }
            .onEnded   { _ in withAnimation(.spring(response: 0.25)) { pressed = false } }
        )
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: FILE EXPLORER
// ─────────────────────────────────────────────────

struct ExplorerView: View {
    @State private var selected: UUID? = nil
    @State private var viewMode: ViewMode = .list
    @State private var currentFolder = "Desktop"
    enum ViewMode { case list, grid }

    let sidebar: [(icon: String, name: String, color: Color)] = [
        ("desktopcomputer", "Desktop",   .blue),
        ("doc.fill",         "Documents", .yellow),
        ("arrow.down.circle.fill", "Downloads", .green),
        ("photo.fill",       "Images",    .purple),
        ("music.note",       "Music",     DS.danger),
        ("internaldrive.fill","System (C:)", .gray),
    ]

    let files: [FileItem] = [
        FileItem(name: "System32",       icon: "folder.fill",       isDirectory: true,  size: "—",      modified: "Today",    color: DS.warning),
        FileItem(name: "Users",          icon: "folder.fill",       isDirectory: true,  size: "—",      modified: "Yesterday",color: DS.warning),
        FileItem(name: "Program Files",  icon: "folder.fill",       isDirectory: true,  size: "—",      modified: "Jan 12",   color: DS.warning),
        FileItem(name: "README.txt",     icon: "doc.text.fill",     isDirectory: false, size: "4 KB",   modified: "Today",    color: DS.textSecond),
        FileItem(name: "setup.exe",      icon: "gearshape.fill",    isDirectory: false, size: "128 KB", modified: "Feb 1",    color: DS.success),
        FileItem(name: "photo.jpg",      icon: "photo.fill",        isDirectory: false, size: "3.2 MB", modified: "Jan 28",   color: Color(hex: "a05ee2")),
        FileItem(name: "audio.mp3",      icon: "music.note",        isDirectory: false, size: "6.8 MB", modified: "Jan 20",   color: DS.danger),
        FileItem(name: "archive.zip",    icon: "archivebox.fill",   isDirectory: false, size: "22 MB",  modified: "Jan 15",   color: DS.accent),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("FAVORITES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(DS.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                ForEach(sidebar, id: \.name) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(item.color)
                            .frame(width: 18)
                        Text(item.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(item.name == currentFolder ? DS.textPrimary : DS.textSecond)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(item.name == currentFolder ? DS.accent.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                    .overlay(
                        item.name == currentFolder
                            ? RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.accent.opacity(0.3))
                            : nil
                    )
                    .padding(.horizontal, 6)
                    .onTapGesture { withAnimation { currentFolder = item.name } }
                }

                Spacer()

                // Storage bar
                VStack(alignment: .leading, spacing: 6) {
                    Text("STORAGE")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(DS.textTertiary)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(DS.bg3).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3).fill(DS.accent).frame(width: 90, height: 4)
                    }
                    Text("89 GB of 256 GB")
                        .font(.system(size: 9))
                        .foregroundColor(DS.textTertiary)
                }
                .padding(12)
            }
            .frame(width: 155)
            .background(DS.bg2.opacity(0.4))

            Divider().background(DS.stroke)

            // Main area
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DS.warning)
                        Text(currentFolder)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DS.textSecond)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        ModeButton(icon: "list.bullet", active: viewMode == .list) { viewMode = .list }
                        ModeButton(icon: "square.grid.2x2", active: viewMode == .grid) { viewMode = .grid }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(DS.bg2.opacity(0.5))

                // Column headers (list only)
                if viewMode == .list {
                    HStack {
                        Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Size").frame(width: 72, alignment: .trailing)
                        Text("Modified").frame(width: 90, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(DS.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(DS.bg2.opacity(0.3))

                    Divider().background(DS.stroke)
                }

                if viewMode == .list {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(files) { file in
                                HStack(spacing: 10) {
                                    Image(systemName: file.icon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(file.color)
                                        .frame(width: 20)
                                    Text(file.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(selected == file.id ? DS.textPrimary : DS.textSecond)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(file.size)
                                        .font(.system(size: 11))
                                        .foregroundColor(DS.textTertiary)
                                        .frame(width: 72, alignment: .trailing)
                                    Text(file.modified)
                                        .font(.system(size: 11))
                                        .foregroundColor(DS.textTertiary)
                                        .frame(width: 90, alignment: .trailing)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selected == file.id ? DS.accent.opacity(0.12) : Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { withAnimation { selected = file.id } }
                            }
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(files) { file in
                                VStack(spacing: 6) {
                                    Image(systemName: file.icon)
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(file.color)
                                        .frame(width: 52, height: 52)
                                        .background(selected == file.id ? DS.accent.opacity(0.12) : DS.bg3)
                                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                                    Text(file.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(DS.textSecond)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .onTapGesture { withAnimation { selected = file.id } }
                            }
                        }
                        .padding(12)
                    }
                }

                // Status bar
                Divider().background(DS.stroke)
                HStack {
                    Text("\(files.count) items\(selected != nil ? " · 1 selected" : "")")
                        .font(.system(size: 10))
                        .foregroundColor(DS.textTertiary)
                    Spacer()
                    Text("C:\\Users\\Admin\\\(currentFolder)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(DS.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DS.bg2.opacity(0.5))
            }
        }
    }
}

struct ModeButton: View {
    let icon: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? DS.accent : DS.textTertiary)
                .frame(width: 28, height: 28)
                .background(active ? DS.accent.opacity(0.15) : DS.bg3)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: SETTINGS
// ─────────────────────────────────────────────────

struct SettingsView: View {
    @EnvironmentObject var os: OSState
    @State private var selected = "Personalization"

    let sections: [(icon: String, name: String)] = [
        ("paintpalette.fill",  "Personalization"),
        ("slider.horizontal.3","System"),
        ("info.circle.fill",   "About"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ForEach(sections, id: \.name) { s in
                    Button { withAnimation { selected = s.name } } label: {
                        HStack(spacing: 8) {
                            Image(systemName: s.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selected == s.name ? DS.accent : DS.textTertiary)
                                .frame(width: 18)
                            Text(s.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selected == s.name ? DS.textPrimary : DS.textSecond)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected == s.name ? DS.accent.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                        .overlay(
                            selected == s.name
                                ? RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.accent.opacity(0.3))
                                : nil
                        )
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 165)
            .background(DS.bg2.opacity(0.4))

            Divider().background(DS.stroke)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    switch selected {
                    case "Personalization":
                        SettingsSection(title: "Wallpaper") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                ForEach(os.wallpapers) { wp in
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: DS.radiusSm)
                                            .fill(wp.gradient())
                                            .frame(height: 58)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DS.radiusSm)
                                                    .stroke(os.wallpaperIndex == wp.id ? DS.accent : DS.stroke, lineWidth: os.wallpaperIndex == wp.id ? 2 : 1)
                                            )
                                        Text(wp.name)
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                            .padding(.horizontal, 6)
                                            .padding(.bottom, 5)
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        if os.wallpaperIndex == wp.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(DS.accent)
                                                .background(Circle().fill(.white).padding(2))
                                                .padding(5)
                                        }
                                    }
                                    .onTapGesture { withAnimation { os.wallpaperIndex = wp.id } }
                                }
                            }
                        }

                        SettingsSection(title: "Display") {
                            SettingsToggleRow(label: "Night Mode", icon: "moon.fill", isOn: $os.isNightMode)
                        }

                    case "System":
                        SettingsSection(title: "Audio & Display") {
                            VStack(spacing: 10) {
                                SettingsSliderRow(label: "Volume", icon: "speaker.wave.2.fill", value: $os.volume)
                                SettingsSliderRow(label: "Brightness", icon: "sun.max.fill", value: $os.brightness)
                            }
                        }

                    case "About":
                        SettingsSection(title: "System Info") {
                            VStack(spacing: 6) {
                                InfoRow2(label: "OS", value: "WindOS 3.0.0")
                                InfoRow2(label: "Build", value: "2025.02.21-stable")
                                InfoRow2(label: "Architecture", value: "ARM64")
                                InfoRow2(label: "Kernel", value: "NovKernel 5.4.0")
                                InfoRow2(label: "Device", value: UIDevice.current.model)
                                InfoRow2(label: "System", value: UIDevice.current.systemVersion)
                            }
                        }

                    default: EmptyView()
                    }
                }
                .padding(20)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundColor(DS.textTertiary)
            content
        }
    }
}

struct SettingsToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(DS.textTertiary).frame(width: 20)
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(DS.textSecond)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(DS.accent)
        }
        .padding(12)
        .background(DS.bg3)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
        .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.stroke))
    }
}

struct SettingsSliderRow: View {
    let label: String
    let icon: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(DS.textTertiary).frame(width: 20)
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(DS.textSecond).frame(width: 80, alignment: .leading)
            Slider(value: $value, in: 0...1).tint(DS.accent)
            Text("\(Int(value * 100))%").font(.system(size: 11)).foregroundColor(DS.textTertiary).frame(width: 36, alignment: .trailing)
        }
        .padding(12)
        .background(DS.bg3)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
        .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.stroke))
    }
}

struct InfoRow2: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(DS.textTertiary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(DS.textSecond)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(DS.bg3)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
        .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.stroke))
    }
}

// ─────────────────────────────────────────────────
// MARK: - APP: PAINT
// ─────────────────────────────────────────────────

struct PaintView: View {
    @State private var lines: [DrawnLine] = []
    @State private var currentLine: DrawnLine? = nil
    @State private var selectedColor: Color = DS.danger
    @State private var brushSize: CGFloat = 5
    @State private var tool: DrawTool = .pen
    @State private var opacity: Double = 1.0

    enum DrawTool: String, CaseIterable {
        case pen = "pencil.tip"
        case eraser = "eraser.fill"
        var label: String { rawValue }
    }

    struct DrawnLine: Identifiable {
        let id = UUID()
        var points: [CGPoint]
        var color: Color
        var width: CGFloat
    }

    let palette: [Color] = [
        DS.textPrimary, Color(hex: "08090a"),
        DS.danger, Color(hex: "e27d5e"),
        DS.warning, DS.success,
        DS.accent, Color(hex: "a05ee2"),
        Color(hex: "e25ea0"), DS.textSecond,
        Color(hex: "5ee2e2"), Color(hex: "e2cc5e"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 10) {
                // Tool selector
                HStack(spacing: 2) {
                    ForEach(DrawTool.allCases, id: \.self) { t in
                        Button { tool = t } label: {
                            Image(systemName: t.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(tool == t ? DS.accent : DS.textTertiary)
                                .frame(width: 32, height: 32)
                                .background(tool == t ? DS.accent.opacity(0.15) : DS.bg3)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Rectangle().fill(DS.stroke).frame(width: 1, height: 20)

                // Brush size
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: brushSize * 0.6))
                        .foregroundColor(selectedColor)
                        .frame(width: 14)
                    Slider(value: $brushSize, in: 1...30).frame(width: 70).tint(DS.accent)
                }

                Rectangle().fill(DS.stroke).frame(width: 1, height: 20)

                // Palette
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(Array(palette.enumerated()), id: \.offset) { _, c in
                            ZStack {
                                Circle().fill(c).frame(width: 22, height: 22)
                                if selectedColor == c {
                                    Circle().stroke(.white, lineWidth: 2).frame(width: 22, height: 22)
                                    Circle().stroke(.black.opacity(0.2), lineWidth: 0.5).frame(width: 26, height: 26)
                                }
                            }
                            .onTapGesture { selectedColor = c; tool = .pen }
                        }
                    }
                }

                Spacer()

                Button {
                    withAnimation { lines.removeAll() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "trash.fill").font(.system(size: 11))
                        Text("Clear").font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DS.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DS.danger.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                    .overlay(RoundedRectangle(cornerRadius: DS.radiusSm).stroke(DS.danger.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DS.bg2.opacity(0.7))

            Divider().background(DS.stroke)

            // Canvas
            GeometryReader { geo in
                ZStack {
                    Color.white

                    // Grid
                    Canvas { ctx, size in
                        for x in stride(from: 0.0, to: size.width, by: 20) {
                            for y in stride(from: 0.0, to: size.height, by: 20) {
                                ctx.fill(Path(CGRect(x: x, y: y, width: 0.5, height: 0.5)), with: .color(Color.black.opacity(0.05)))
                            }
                        }
                    }

                    Canvas { ctx, _ in
                        for line in lines { drawLine(ctx: ctx, line: line) }
                        if let cur = currentLine { drawLine(ctx: ctx, line: cur) }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let pt = val.location
                            guard pt.x >= 0, pt.y >= 0, pt.x <= geo.size.width, pt.y <= geo.size.height else { return }
                            if currentLine == nil {
                                currentLine = DrawnLine(
                                    points: [pt],
                                    color: tool == .eraser ? .white : selectedColor,
                                    width: tool == .eraser ? brushSize * 3 : brushSize
                                )
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
        for i in 1..<line.points.count {
            let mid = CGPoint(x: (line.points[i-1].x + line.points[i].x) / 2,
                              y: (line.points[i-1].y + line.points[i].y) / 2)
            path.addQuadCurve(to: mid, control: line.points[i-1])
        }
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
        ("New York",  "America/New_York",     "🇺🇸"),
        ("London",    "Europe/London",         "🇬🇧"),
        ("Paris",     "Europe/Paris",          "🇫🇷"),
        ("Dubai",     "Asia/Dubai",            "🇦🇪"),
        ("Tokyo",     "Asia/Tokyo",            "🇯🇵"),
        ("Sydney",    "Australia/Sydney",      "🇦🇺"),
        ("Local",     TimeZone.current.identifier, "🏠"),
    ]

    func timeIn(_ id: String) -> String {
        let tz = TimeZone(identifier: id) ?? .current
        let fmt = DateFormatter(); fmt.timeStyle = .short; fmt.timeZone = tz
        return fmt.string(from: time)
    }

    func offsetLabel(_ id: String) -> String {
        let tz = TimeZone(identifier: id) ?? .current
        let off = tz.secondsFromGMT() / 3600
        return off >= 0 ? "UTC+\(off)" : "UTC\(off)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Analog clock
            ClockFaceView(time: time)
                .padding(.vertical, 16)
                .frame(height: 160)

            Divider().background(DS.stroke)

            // World clocks
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(zones, id: \.id) { zone in
                        HStack(alignment: .center) {
                            Text(zone.flag).font(.title3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(zone.city)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DS.textSecond)
                                Text(offsetLabel(zone.id))
                                    .font(.system(size: 10))
                                    .foregroundColor(DS.textTertiary)
                            }
                            Spacer()
                            Text(timeIn(zone.id))
                                .font(.system(size: 20, weight: .thin, design: .rounded))
                                .foregroundColor(DS.textPrimary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(DS.bg3)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm))
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .onReceive(timer) { t in time = t }
    }
}

struct ClockFaceView: View {
    let time: Date
    var cal: Calendar { .current }
    var secs: Double  { Double(cal.component(.second, from: time)) }
    var mins: Double  { Double(cal.component(.minute, from: time)) + secs / 60 }
    var hours: Double { Double(cal.component(.hour, from: time) % 12) + mins / 60 }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let r = s / 2
            ZStack {
                // Face rings
                Circle()
                    .fill(DS.bg3)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 6)

                Circle().stroke(DS.stroke, lineWidth: 1)
                Circle().stroke(DS.accent.opacity(0.2), lineWidth: 1).padding(6)

                // Hour ticks
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(i % 3 == 0 ? DS.textSecond : DS.textTertiary)
                        .frame(width: i % 3 == 0 ? 2 : 1, height: i % 3 == 0 ? r * 0.12 : r * 0.07)
                        .offset(y: -(r - r * 0.08))
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                // Hour hand
                ClockHand(color: DS.textPrimary, width: 4, length: r * 0.48, angle: hours * 30 - 90)
                // Minute hand
                ClockHand(color: DS.textPrimary, width: 2.5, length: r * 0.68, angle: mins * 6 - 90)
                // Second hand
                ClockHand(color: DS.danger, width: 1.5, length: r * 0.76, angle: secs * 6 - 90)

                // Center cap
                Circle().fill(DS.bg2).frame(width: 12, height: 12)
                    .overlay(Circle().stroke(DS.danger, lineWidth: 2))
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

struct ClockHand: View {
    let color: Color; let width: CGFloat; let length: CGFloat; let angle: Double
    var body: some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(color)
            .frame(width: width, height: length)
            .shadow(color: color.opacity(0.5), radius: 3)
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
