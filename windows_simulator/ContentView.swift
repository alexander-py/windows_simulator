import SwiftUI

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
    var isMinimized: Bool = false // New state for minimizing
}

struct ContentView: View {
    @State private var isStartMenuOpen = false
    @State private var windows: [WindowModel] = []

    var body: some View {
        ZStack {
            // --- Desktop Background ---
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .onTapGesture { isStartMenuOpen = false }

            // --- Window Layer ---
            ForEach(windows.indices, id: \.self) { index in
                if !windows[index].isMinimized {
                    WindowView(window: $windows[index],
                               onClose: { windows.remove(at: index) },
                               onMinimize: { windows[index].isMinimized = true })
                        .onTapGesture { bringToFront(index) }
                        .zIndex(Double(index))
                }
            }

            // --- Start Menu ---
            if isStartMenuOpen {
                StartMenuView(openApp: { app in
                    openApp(app)
                    isStartMenuOpen = false
                }, onPowerOff: {
                    windows.removeAll() // The "Turn Off" functionality
                    isStartMenuOpen = false
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }

            // --- Taskbar ---
            VStack {
                Spacer()
                TaskbarView(isStartMenuOpen: $isStartMenuOpen, windows: $windows)
            }
        }
    }

    func openApp(_ type: AppType) {
        let newWindow = WindowModel(
            type: type,
            title: type == .commandPrompt ? "Command Prompt" : "Notepad",
            color: type == .commandPrompt ? .black : .white,
            position: CGPoint(x: 300 + CGFloat(windows.count * 20), y: 300 + CGFloat(windows.count * 20))
        )
        windows.append(newWindow)
    }

    func bringToFront(_ index: Int) {
        let window = windows.remove(at: index)
        windows.append(window)
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
            HStack(spacing: 12) {
                Text(window.title).font(.system(size: 12, weight: .bold)).padding(.leading, 8)
                Spacer()
                // Minimize Button
                Button(action: onMinimize) {
                    Image(systemName: "minus").foregroundColor(.white).font(.system(size: 10, weight: .bold))
                }
                // Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark").foregroundColor(.white).font(.system(size: 10, weight: .bold))
                }
                .padding(.trailing, 8)
            }
            .frame(height: 30)
            .background(Color.blue.opacity(0.9))
            .gesture(DragGesture().onChanged { value in
                window.position.x += value.translation.width
                window.position.y += value.translation.height
            })

            // Content
            Rectangle()
                .fill(window.color)
                .overlay(
                    Text(window.type == .commandPrompt ? "Microsoft Windows [Version 10.0.2026]\n(c) Corporation. All rights reserved.\n\nC:\\Users\\Admin> _" : "Untitled - Notepad\n\nFile  Edit  Format  View  Help")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(window.type == .commandPrompt ? .green : .gray)
                        .padding(),
                    alignment: .topLeading
                )
        }
        .frame(width: 400, height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.3), radius: 15)
        .position(window.position)
    }
}

// MARK: - Start Menu
struct StartMenuView: View {
    var openApp: (AppType) -> Void
    var onPowerOff: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("Pinned").font(.headline).padding([.top, .leading])
                HStack(spacing: 25) {
                    StartMenuIcon(name: "Terminal", icon: "terminal.fill", color: .black) { openApp(.commandPrompt) }
                    StartMenuIcon(name: "Notepad", icon: "doc.text.fill", color: .blue) { openApp(.notepad) }
                }.padding()
                
                Spacer()
                
                HStack {
                    Label("Admin", systemImage: "person.circle.fill")
                    Spacer()
                    Button(action: onPowerOff) {
                        Image(systemName: "power").foregroundColor(.red).font(.title3)
                    }
                }
                .padding().background(Color.primary.opacity(0.05))
            }
            .frame(width: 350, height: 450)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .padding(.bottom, 65)
        }
    }
}

struct StartMenuIcon: View {
    let name: String; let icon: String; let color: Color; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.largeTitle).foregroundColor(color)
                Text(name).font(.caption2).foregroundColor(.primary)
            }.frame(width: 60)
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
            
            Divider().frame(height: 25)
            
            // App icons for currently running apps
            ForEach(windows.indices, id: \.self) { i in
                Button(action: { windows[i].isMinimized.toggle() }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(windows[i].isMinimized ? Color.clear : Color.white.opacity(0.2))
                        Image(systemName: windows[i].type == .commandPrompt ? "terminal" : "doc.text")
                            .foregroundColor(windows[i].isMinimized ? .gray : .white)
                    }
                    .frame(width: 35, height: 35)
                }
            }

            Spacer()
            Text(Date(), style: .time).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal)
        .frame(height: 50)
        .background(.ultraThinMaterial)
    }
}


#Preview {
    ContentView()
}
