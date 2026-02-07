import SwiftUI
import WebKit

// MARK: - 1. Global Models
enum AppType {
    case commandPrompt, notepad, browser, calculator, explorer, settings
}

struct WindowModel: Identifiable {
    let id = UUID()
    var type: AppType
    var title: String
    var color: Color
    var position: CGPoint
    var isOpen: Bool = true
    var isMinimized: Bool = false
    var urlString: String = "https://www.google.com"
}

// MARK: - 2. MAIN SYSTEM VIEW
struct ContentView: View {
    @State private var isStartMenuOpen = false
    @State private var isBSODActive = false
    @State private var windows: [WindowModel] = []
    @State private var desktopColor: Color = .cyan

    var body: some View {
        ZStack {
            desktopColor.ignoresSafeArea()
                .onTapGesture { isStartMenuOpen = false }

            desktopLayer
            windowLayer

            if isStartMenuOpen {
                startMenuOverlay
            }

            VStack {
                Spacer()
                TaskbarView(isStartMenuOpen: $isStartMenuOpen, windows: $windows)
            }

            if isBSODActive { BSODView().zIndex(2000) }
        }
    }

    private var desktopLayer: some View {
        VStack(alignment: .leading, spacing: 25) {
            DesktopIcon(name: "My PC", icon: "desktopcomputer", color: .white) { openApp(.explorer) }
            DesktopIcon(name: "Edge", icon: "globe.americas.fill", color: .blue) { openApp(.browser) }
            DesktopIcon(name: "Trash", icon: "trash.fill", color: .white.opacity(0.8)) { }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var windowLayer: some View {
        ForEach(windows.indices, id: \.self) { index in
            if !windows[index].isMinimized {
                WindowView(window: $windows[index],
                           onClose: { windows.remove(at: index) },
                           onMinimize: { windows[index].isMinimized = true },
                           desktopColor: $desktopColor)
                    .onTapGesture { bringToFront(index) }
                    .zIndex(Double(index))
            }
        }
    }

    private var startMenuOverlay: some View {
        StartMenuView(openApp: { app in
            openApp(app)
            isStartMenuOpen = false
        }, onTriggerBSOD: { triggerBSOD() })
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(1000)
    }

    func openApp(_ type: AppType) {
        if let existingIndex = windows.firstIndex(where: { $0.type == type }) {
            windows[existingIndex].isMinimized = false
            bringToFront(existingIndex)
        } else {
            let config = getAppConfig(type)
            let newWindow = WindowModel(type: type, title: config.0, color: config.1, position: CGPoint(x: 350, y: 350))
            windows.append(newWindow)
        }
    }

    func getAppConfig(_ type: AppType) -> (String, Color) {
        switch type {
        case .commandPrompt: return ("Command Prompt", .black)
        case .notepad: return ("Notepad", .white)
        case .browser: return ("Microsoft Edge", .white)
        case .calculator: return ("Calculator", Color(.systemGray6))
        case .explorer: return ("File Explorer", .white)
        case .settings: return ("Settings", Color(.systemGray6))
        }
    }

    func bringToFront(_ index: Int) {
        guard windows.indices.contains(index) else { return }
        let window = windows.remove(at: index)
        windows.append(window)
    }

    func triggerBSOD() {
        isStartMenuOpen = false; isBSODActive = true; windows.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { isBSODActive = false }
    }
}

// MARK: - 3. FULLY FUNCTIONAL CALCULATOR
struct CalculatorView: View {
    @State private var display = "0"
    @State private var accumulatedValue: Double = 0
    @State private var currentOperator: String? = nil
    @State private var isTypingNumber = false

    let buttons = [
        ["C", "±", "%", "/"],
        ["7", "8", "9", "*"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text(display)
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.black.opacity(0.05))
                .cornerRadius(4)

            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { label in
                        Button(action: { handlePress(label) }) {
                            Text(label)
                                .font(.title3)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(btnColor(label))
                                .foregroundColor(btnTextColor(label))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
    }

    func handlePress(_ label: String) {
        if let _ = Int(label) {
            if !isTypingNumber || display == "0" {
                display = label
                isTypingNumber = true
            } else {
                display += label
            }
        } else {
            switch label {
            case ".":
                if !display.contains(".") { display += "." }
            case "C":
                display = "0"
                accumulatedValue = 0
                currentOperator = nil
                isTypingNumber = false
            case "+", "-", "*", "/":
                calculate()
                currentOperator = label
                accumulatedValue = Double(display) ?? 0
                isTypingNumber = false
            case "=":
                calculate()
                currentOperator = nil
                isTypingNumber = false
            case "±":
                if let val = Double(display) { display = "\(val * -1)" }
            case "%":
                if let val = Double(display) { display = "\(val / 100)" }
            default: break
            }
        }
    }

    func calculate() {
        guard let op = currentOperator, let currentVal = Double(display) else { return }
        var result: Double = 0
        switch op {
        case "+": result = accumulatedValue + currentVal
        case "-": result = accumulatedValue - currentVal
        case "*": result = accumulatedValue * currentVal
        case "/": result = currentVal != 0 ? accumulatedValue / currentVal : 0
        default: return
        }
        display = formatResult(result)
        accumulatedValue = result
    }

    func formatResult(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }

    func btnColor(_ label: String) -> Color {
        if ["+", "-", "*", "/", "="].contains(label) { return .orange }
        if ["C", "±", "%"].contains(label) { return Color.gray.opacity(0.3) }
        return Color.gray.opacity(0.1)
    }
    
    func btnTextColor(_ label: String) -> Color {
        return ["+", "-", "*", "/", "="].contains(label) ? .white : .primary
    }
}

// MARK: - 4. WINDOW COMPONENT
struct WindowView: View {
    @Binding var window: WindowModel
    var onClose: () -> Void
    var onMinimize: () -> Void
    @Binding var desktopColor: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(window.title).font(.caption).bold().padding(.leading, 10)
                Spacer()
                Button(action: onMinimize) { Image(systemName: "minus").padding(5) }
                Button(action: onClose) { Image(systemName: "xmark").padding(5) }
            }
            .foregroundColor(.white).frame(height: 32).background(Color.blue)
            .gesture(DragGesture().onChanged { v in
                window.position.x += v.translation.width
                window.position.y += v.translation.height
            })

            Group {
                switch window.type {
                case .browser:
                    VStack(spacing: 0) {
                        TextField("Search...", text: $window.urlString).textFieldStyle(.roundedBorder).padding(5).font(.caption)
                        WebView(urlString: window.urlString)
                    }
                case .calculator: CalculatorView()
                case .explorer: ExplorerView()
                case .settings: SettingsView(desktopColor: $desktopColor)
                case .commandPrompt:
                    Color.black.overlay(Text("C:\\Users\\Admin> _").foregroundColor(.green).font(.system(.caption, design: .monospaced)).padding(), alignment: .topLeading)
                case .notepad:
                    TextEditor(text: .constant("")).font(.body).padding(5)
                }
            }.background(window.color)
        }
        .frame(width: 420, height: 450).clipShape(RoundedRectangle(cornerRadius: 6)).shadow(radius: 10).position(window.position)
    }
}

// MARK: - 5. SUPPORTING VIEWS (Settings, Explorer, Start, etc.)
struct SettingsView: View {
    @Binding var desktopColor: Color
    let colors: [Color] = [.cyan, .orange, .purple, .black, .green, .pink]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Personalization").font(.headline).padding(.bottom)
            Text("Desktop Color:").font(.caption)
            HStack {
                ForEach(colors, id: \.self) { c in
                    Circle().fill(c).frame(width: 30).onTapGesture { desktopColor = c }
                }
            }
            Spacer()
        }.padding()
    }
}

struct ExplorerView: View {
    var body: some View {
        List {
            Label("Documents", systemImage: "folder.fill")
            Label("Images", systemImage: "photo.on.rectangle")
            Label("System (C:)", systemImage: "internaldrive")
        }.listStyle(.plain)
    }
}

struct DesktopIcon: View {
    let name: String; let icon: String; let color: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.system(size: 40)).foregroundColor(color).shadow(radius: 2)
                Text(name).font(.caption).foregroundColor(.white).bold().shadow(radius: 1)
            }.frame(width: 70)
        }
    }
}

struct StartMenuView: View {
    var openApp: (AppType) -> Void
    var onTriggerBSOD: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StartMenuBtn(n: "CMD", i: "terminal", c: .black) { openApp(.commandPrompt) }
                        StartMenuBtn(n: "Notepad", i: "doc.text", c: .blue) { openApp(.notepad) }
                        StartMenuBtn(n: "Edge", i: "globe", c: .blue) { openApp(.browser) }
                        StartMenuBtn(n: "Calc", i: "plus.forwardslash.minus", c: .orange) { openApp(.calculator) }
                        StartMenuBtn(n: "Settings", i: "gearshape.fill", c: .gray) { openApp(.settings) }
                    }.padding()
                }
                HStack {
                    Label("Admin", systemImage: "person.circle.fill")
                    Spacer()
                    Button(action: onTriggerBSOD) { Image(systemName: "power").foregroundColor(.red) }
                }.padding().background(Color.black.opacity(0.1))
            }
            .frame(width: 350, height: 450).background(.ultraThinMaterial).cornerRadius(12).padding(.bottom, 65)
        }
    }
}

struct StartMenuBtn: View {
    let n: String; let i: String; let c: Color; var a: () -> Void
    var body: some View {
        Button(action: a) {
            VStack {
                Image(systemName: i).font(.title).foregroundColor(c)
                Text(n).font(.caption2).foregroundColor(.primary)
            }
        }
    }
}

struct TaskbarView: View {
    @Binding var isStartMenuOpen: Bool
    @Binding var windows: [WindowModel]
    var body: some View {
        HStack(spacing: 15) {
            Button { isStartMenuOpen.toggle() } label: { Image(systemName: "square.grid.2x2.fill").font(.title2) }
            Divider().frame(height: 25)
            ForEach(windows.indices, id: \.self) { i in
                Button { windows[i].isMinimized.toggle() } label: {
                    Image(systemName: iconFor(windows[i].type))
                        .padding(8).background(windows[i].isMinimized ? Color.clear : Color.white.opacity(0.25)).cornerRadius(4)
                }
            }
            Spacer()
            Text(Date(), style: .time).font(.caption2).monospacedDigit()
        }.padding(.horizontal).frame(height: 50).background(.ultraThinMaterial)
    }
    func iconFor(_ t: AppType) -> String {
        switch t { case .commandPrompt: return "terminal"; case .notepad: return "doc.text"; case .browser: return "globe"; case .calculator: return "plus.forwardslash.minus"; case .explorer: return "folder"; case .settings: return "gearshape" }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) { uiView.load(URLRequest(url: url)) }
    }
}

struct BSODView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text(":(").font(.system(size: 100))
            Text("Your PC ran into a problem.").font(.title)
        }.padding(50).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.blue).ignoresSafeArea()
    }
}
#Preview {
    ContentView()
}
