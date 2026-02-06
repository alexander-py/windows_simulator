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
    var urlString: String = "https://www.google.com" // Default for browser
}

// MARK: - Web View Wrapper
struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var isStartMenuOpen = false
    @State private var isBSODActive = false
    @State private var windows: [WindowModel] = []

    var body: some View {
        ZStack {
            // 1. Desktop Background
            Color.cyan.ignoresSafeArea()
                .onTapGesture { isStartMenuOpen = false }

            // 2. Window Layer
            ForEach(windows.indices, id: \.self) { index in
                if !windows[index].isMinimized {
                    WindowView(window: $windows[index],
                               onClose: { windows.remove(at: index) },
                               onMinimize: { windows[index].isMinimized = true })
                        .onTapGesture { bringToFront(index) }
                        .zIndex(Double(index))
                }
            }

            // 3. Start Menu
            if isStartMenuOpen {
                StartMenuView(openApp: { app in
                    openApp(app)
                    isStartMenuOpen = false
                }, onTriggerBSOD: {
                    triggerBSOD()
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }

            // 4. Taskbar
            VStack {
                Spacer()
                TaskbarView(isStartMenuOpen: $isStartMenuOpen, windows: $windows)
            }

            // 5. BSOD Overlay
            if isBSODActive {
                BSODView()
                    .zIndex(1000)
            }
        }
    }

    func openApp(_ type: AppType) {
        let title = type == .commandPrompt ? "CMD" : (type == .notepad ? "Notepad" : "Edge Browser")
        let color: Color = type == .commandPrompt ? .black : .white
        
        let newWindow = WindowModel(
            type: type,
            title: title,
            color: color,
            position: CGPoint(x: 350 + CGFloat(windows.count * 20), y: 350 + CGFloat(windows.count * 20))
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
        // Reboot after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isBSODActive = false
        }
    }
}

// MARK: - Window View
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
                Button(action: onMinimize) { Image(systemName: "minus") }
                Button(action: onClose) { Image(systemName: "xmark") }
                .padding(.trailing, 8)
            }
            .foregroundColor(.white).frame(height: 30).background(Color.blue)
            .gesture(DragGesture().onChanged { value in
                window.position.x += value.translation.width
                window.position.y += value.translation.height
            })

            // App Content
            Group {
                if window.type == .browser {
                    WebView(urlString: window.urlString)
                } else {
                    Rectangle()
                        .fill(window.color)
                        .overlay(
                            Text(window.type == .commandPrompt ? "Microsoft Windows [Version 10.0.2026]\n(c) Corporation. All rights reserved.\n\nC:\\Users\\Admin> _" : "Untitled - Notepad\n\nFile  Edit  Format  View  Help")
                                .foregroundColor(window.type == .commandPrompt ? .green : .black)
                                .padding(),
                            alignment: .topLeading
                        )
                }
            }
        }
        .frame(width: 500, height: 350)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 10)
        .position(window.position)
    }
}

// MARK: - Start Menu
struct StartMenuView: View {
    var openApp: (AppType) -> Void
    var onTriggerBSOD: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("Pinned").font(.headline).padding([.top, .leading])
                HStack(spacing: 25) {
                    StartMenuIcon(name: "Terminal", icon: "terminal.fill", color: .black) { openApp(.commandPrompt) }
                    StartMenuIcon(name: "Notepad", icon: "doc.text.fill", color: .blue) { openApp(.notepad) }
                    StartMenuIcon(name: "Edge", icon: "globe", color: .blue) { openApp(.browser) }
                }.padding()
                Spacer()
                HStack {
                    Label("Admin", systemImage: "person.circle.fill")
                    Spacer()
                    Button(action: onTriggerBSOD) {
                        Image(systemName: "power").foregroundColor(.red)
                    }
                }.padding().background(Color.black.opacity(0.1))
            }
            .frame(width: 300, height: 400).background(.ultraThinMaterial).cornerRadius(15).padding(.bottom, 65)
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

// MARK: - Taskbar
struct TaskbarView: View {
    @Binding var isStartMenuOpen: Bool
    @Binding var windows: [WindowModel]

    var body: some View {
        HStack(spacing: 15) {
            Button(action: { withAnimation { isStartMenuOpen.toggle() } }) {
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

// MARK: - BSOD View
struct BSODView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(":(").font(.system(size: 100))
            Text("Your PC ran into a problem and needs to restart. We're just collecting some error info, and then we'll restart for you.")
                .font(.title2)
            Text("0% complete").font(.title3)
            Spacer()
        }
        .padding(100).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0, green: 0.47, blue: 0.83)).ignoresSafeArea()
    }
}


#Preview {
    ContentView()
}
