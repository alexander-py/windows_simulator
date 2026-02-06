import SwiftUI
import WebKit

// MARK: - Models
enum AppType {
    case commandPrompt, notepad, browser
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

// MARK: - Updated Main View
struct ContentView: View {
    @State private var isStartMenuOpen = false
    @State private var isBSODActive = false
    @State private var windows: [WindowModel] = []
    @State private var urlInput: String = "https://www.google.com"

    var body: some View {
        ZStack {
            // 1. Desktop Background (Cyan)
            Color.cyan.ignoresSafeArea()
                .onTapGesture { isStartMenuOpen = false }

            // 2. Desktop Icons Layer
            VStack(alignment: .leading, spacing: 30) {
                DesktopIcon(name: "My PC", icon: "desktopcomputer", color: .white) { openApp(.commandPrompt) }
                DesktopIcon(name: "Internet", icon: "globe", color: .blue) { openApp(.browser) }
                DesktopIcon(name: "Trash", icon: "trash", color: .white) { }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // 3. Window Layer
            ForEach(windows.indices, id: \.self) { index in
                if !windows[index].isMinimized {
                    WindowView(window: $windows[index],
                               onClose: { windows.remove(at: index) },
                               onMinimize: { windows[index].isMinimized = true })
                        .onTapGesture { bringToFront(index) }
                        .zIndex(Double(index))
                }
            }

            // 4. Start Menu
            if isStartMenuOpen {
                StartMenuView(openApp: { app in
                    openApp(app)
                    isStartMenuOpen = false
                }, onTriggerBSOD: { triggerBSOD() })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }

            // 5. Taskbar
            VStack {
                Spacer()
                TaskbarView(isStartMenuOpen: $isStartMenuOpen, windows: $windows)
            }

            // 6. BSOD
            if isBSODActive {
                BSODView().zIndex(2000)
            }
        }
    }

    func openApp(_ type: AppType) {
        let title = type == .commandPrompt ? "CMD" : (type == .notepad ? "Notepad" : "Edge Browser")
        let newWindow = WindowModel(
            type: type,
            title: title,
            color: type == .commandPrompt ? .black : .white,
            position: CGPoint(x: 300 + CGFloat(windows.count * 20), y: 300 + CGFloat(windows.count * 20))
        )
        windows.append(newWindow)
    }

    func bringToFront(_ index: Int) {
        guard windows.indices.contains(index) else { return }
        let window = windows.remove(at: index)
        windows.append(window)
    }

    func triggerBSOD() {
        isStartMenuOpen = false
        isBSODActive = true
        windows.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { isBSODActive = false }
    }
}

// MARK: - Desktop Icon Component
struct DesktopIcon: View {
    let name: String; let icon: String; let color: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.largeTitle).foregroundColor(color)
                    .shadow(radius: 2)
                Text(name).font(.caption).foregroundColor(.white).bold()
            }.frame(width: 80)
        }
    }
}

// MARK: - Updated Window View with Address Bar
struct WindowView: View {
    @Binding var window: WindowModel
    var onClose: () -> Void
    var onMinimize: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                Text(window.title).font(.system(size: 12, weight: .bold)).padding(.leading, 8)
                Spacer()
                Button(action: onMinimize) { Image(systemName: "minus") }.padding(.trailing, 5)
                Button(action: onClose) { Image(systemName: "xmark") }.padding(.trailing, 8)
            }
            .foregroundColor(.white).frame(height: 30).background(Color.blue)
            .gesture(DragGesture().onChanged { value in
                window.position.x += value.translation.width
                window.position.y += value.translation.height
            })

            // Browser Address Bar
            if window.type == .browser {
                HStack {
                    TextField("Enter URL", text: $window.urlString)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    Button("Go") {}.buttonStyle(.borderedProminent).controlSize(.mini)
                }
                .padding(5).background(Color(.systemGray6))
            }

            // Content Area
            if window.type == .browser {
                WebView(urlString: window.urlString)
            } else {
                Rectangle().fill(window.color).overlay(
                    Text(window.type == .commandPrompt ? "Microsoft(R) Windows\nC:\\> _" : "Welcome to Notepad")
                        .foregroundColor(window.type == .commandPrompt ? .green : .black)
                        .padding(), alignment: .topLeading
                )
            }
        }
        .frame(width: 450, height: 350)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 15)
        .position(window.position)
    }
}

// MARK: - Subviews (Browser, Start, Taskbar, BSOD)
struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) { uiView.load(URLRequest(url: url)) }
    }
}

struct StartMenuView: View {
    var openApp: (AppType) -> Void
    var onTriggerBSOD: () -> Void
    var body: some View {
        VStack {
            Spacer()
            VStack {
                HStack(spacing: 20) {
                    StartMenuIcon(name: "CMD", icon: "terminal.fill", color: .black) { openApp(.commandPrompt) }
                    StartMenuIcon(name: "Notepad", icon: "doc.text.fill", color: .blue) { openApp(.notepad) }
                    StartMenuIcon(name: "Edge", icon: "globe", color: .blue) { openApp(.browser) }
                }.padding()
                Spacer()
                Button(action: onTriggerBSOD) {
                    Label("Shut Down", systemImage: "power").foregroundColor(.red).padding()
                }
            }
            .frame(width: 320, height: 400).background(.ultraThinMaterial).cornerRadius(15).padding(.bottom, 65)
        }
    }
}

struct StartMenuIcon: View {
    let name: String; let icon: String; let color: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.title).foregroundColor(color)
                Text(name).font(.caption2).foregroundColor(.primary)
            }
        }
    }
}

struct TaskbarView: View {
    @Binding var isStartMenuOpen: Bool
    @Binding var windows: [WindowModel]
    var body: some View {
        HStack {
            Button(action: { isStartMenuOpen.toggle() }) {
                Image(systemName: "square.grid.2x2.fill").font(.title2)
            }
            Divider().frame(height: 30)
            ForEach(windows.indices, id: \.self) { i in
                Button(action: { windows[i].isMinimized.toggle() }) {
                    Image(systemName: windows[i].type == .commandPrompt ? "terminal" : (windows[i].type == .browser ? "globe" : "doc.text"))
                        .padding(8).background(windows[i].isMinimized ? Color.clear : Color.white.opacity(0.3)).cornerRadius(5)
                }
            }
            Spacer()
            Text(Date(), style: .time).font(.caption)
        }
        .padding(.horizontal).frame(height: 50).background(.ultraThinMaterial)
    }
}

struct BSODView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(":(").font(.system(size: 80))
            Text("Your PC ran into a problem.").font(.title)
            Text("We're just collecting some error info...").font(.body)
            Spacer()
        }.padding(50).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.blue).ignoresSafeArea()
    }
}


#Preview {
    ContentView()
}
