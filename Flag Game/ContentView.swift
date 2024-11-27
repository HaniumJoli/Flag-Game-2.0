
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var isLoggedIn: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if isLoggedIn {
                MainMenuView()
            } else {
                AuthView()
            }
        }
        .onAppear(perform: setupAuthStateListener)
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { _, user in
            isLoggedIn = user != nil
            isLoading = false
        }
    }
}

struct MainMenuView: View {
    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                RadialGradient(stops: [
                    .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                    .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)
                ], center: .top, startRadius: 200, endRadius: 700)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Text("Flag Game")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.bottom, 40)

                    Button("New Game") {
                        path.append(.game)
                    }
                    .buttonStyle(MenuButtonStyle())

                    Button("High Scores") {
                        path.append(.highScores)
                    }
                    .buttonStyle(MenuButtonStyle())

                    Button("Log Out") {
                        logOut()
                    }
                    .buttonStyle(MenuButtonStyle())
                }
                .padding(20)
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .game:
                    GameView()
                case .highScores:
                    ScoreView()
                }
            }
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
}

enum Destination: Hashable {
    case game
    case highScores
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

#Preview {
    ContentView()
}
