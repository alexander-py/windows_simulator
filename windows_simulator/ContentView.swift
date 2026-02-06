import SwiftUI

// 1. Updated Model to include a type for identification
enum AppType {
    case commandPrompt, notepad
}

struct WindowModel: Identifiable {
    let id = UUID()
    var type: AppType
    var title: String
    var color: Color
    var position: CGPoint
    var isOpen: Bool = true
}

struct ContentView: View {
    @State private var isStartMenuOpen = false
    @State private var windows: [WindowModel] = [] // Start with no windows open

    var body: some View {
        ZStack {
            // --- Desktop Background ---
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .onTapGesture { isStartMenuOpen = false }

            // --- Window Layer ---
            ForEach(windows.indices, id: \.self) { index in
                WindowView(window: $windows[index], onClose: {
                    removeWindow(at: index)
                })
                .onTapGesture { bringToFront(index) }
            }

            // --- Start Menu Layer ---
            if isStartMenuOpen {
                StartMenuView(openApp: { app in
                    openApp(app)
                    isStartMenuOpen = false
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }

            // --- Taskbar Layer ---
            VStack {
                Spacer()
                TaskbarView(isStartMenuOpen: $isStartMenuOpen)
            }
        }
    }

    // Logic to open a new window
    func openApp(_ type: AppType) {
        let newWindow: WindowModel
        switch type {
        case .commandPrompt:
            newWindow = WindowModel(type: .commandPrompt, title: "Command Prompt", color: .black, position: CGPoint(x: 250, y: 250))
        case .notepad:
            newWindow = WindowModel(type: .notepad, title: "Notepad", color: .white, position: CGPoint(x: 400, y: 300))
        }
        windows.append(newWindow)
    }

    func removeWindow(at index: Int) {
        windows.remove(at: index)
    }

    func bringToFront(_ index: Int) {
        guard windows.indices.contains(index) else { return }
        let window = windows.remove(at: index)
        windows.append(window)
    }
}

// MARK: - Window View
struct WindowView: View {
    @Binding var window: WindowModel
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(window.title).font(.system(size: 12, weight: .bold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                }
            }
            .padding(.horizontal, 8).frame(height: 30)
            .background(Color.secondary.opacity(0.8))
            .gesture(DragGesture().onChanged { value in
                window.position.x += value.translation.width
                window.position.y += value.translation.height
            })

            Rectangle()
                .fill(window.color)
                .overlay(
                    Text(window.type == .commandPrompt ? "C:\\Users\\Admin> _" : "Welcome to Notepad...")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(window.type == .commandPrompt ? .green : .black)
                        .padding(),
                    alignment: .topLeading
                )
        }
        .frame(width: 400, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 20)
        .position(window.position)
    }
}

// MARK: - Start Menu
struct StartMenuView: View {
    var openApp: (AppType) -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("Pinned").font(.headline).padding([.top, .leading])
                
                HStack(spacing: 30) {
                    // App 1: CMD
                    Button(action: { openApp(.commandPrompt) }) {
                        VStack {
                            Image(systemName: "terminal.fill").font(.largeTitle).foregroundColor(.black)
                            Text("CMD").font(.caption)
                        }
                    }
                    
                    // App 2: Notepad
                    Button(action: { openApp(.notepad) }) {
                        VStack {
                            Image(systemName: "doc.text.fill").font(.largeTitle).foregroundColor(.blue)
                            Text("Notepad").font(.caption)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Circle().frame(width: 30, height: 30).foregroundColor(.gray)
                    Text("User")
                    Spacer()
                    Image(systemName: "power")
                }
                .padding().background(Color.black.opacity(0.05))
            }
            .frame(width: 400, height: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding(.bottom, 65)
        }
    }
}

// MARK: - Taskbar
struct TaskbarView: View {
    @Binding var isStartMenuOpen: Bool

    var body: some View {
        HStack {
            Button(action: { withAnimation { isStartMenuOpen.toggle() } }) {
                Image(systemName: "square.grid.2x2.fill").font(.title2)
            }
            Spacer()
            Text(Date(), style: .time).font(.caption)
        }
        .padding(.horizontal)
        .frame(height: 50)
        .background(.ultraThinMaterial)
    }
}



#Preview {
    ContentView()
}
