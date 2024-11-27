import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GameView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var countries = ["Estonia", "France", "Germany", "Ireland", "Italy", "Nigeria", "Poland", "Spain", "UK", "Ukraine", "US"].shuffled()
    @State private var correctAnswer = Int.random(in: 0...2)
    @State private var currentQuestion = 1
    @State private var totalQuestions = 10
    @State private var score = 0
    @State private var consecutiveCorrect = 0
    @State private var consecutiveWrong = 0
    @State private var showingScore = false
    @State private var scoreTitle = ""
    @State private var showingFinalScore = false

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            RadialGradient(stops: [
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)
            ], center: .top, startRadius: 200, endRadius: 700)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Guess the Flag")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 15) {
                    VStack {
                        Text("Question \(currentQuestion) of \(totalQuestions)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline.weight(.heavy))

                        Text("Tap the flag of")
                            .foregroundStyle(.secondary)
                            .font(.subheadline.weight(.heavy))

                        Text(countries[correctAnswer])
                            .font(.largeTitle.weight(.semibold))
                    }

                    ForEach(0..<3) { number in
                        Button {
                            flagTapped(number)
                        } label: {
                            Image(countries[number])
                                .clipShape(.capsule)
                                .shadow(radius: 5)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
                Spacer()

                Text("Score: \(score)")
                    .foregroundStyle(.white)
                    .font(.title.bold())

                Spacer()
            }
            .padding()
        }
        .alert(scoreTitle, isPresented: $showingScore) {
            Button(currentQuestion == totalQuestions ? "Finish" : "Continue", action: askQuestion)
        } message: {
            Text(currentQuestion == totalQuestions ? "Your final score is \(score)" : "Your score is \(score)")
        }
        .alert("Game Over", isPresented: $showingFinalScore) {
            Button("OK") {
                saveScoreIfTop10()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your final score is \(score)")
        }
    }

    func flagTapped(_ number: Int) {
        if number == correctAnswer {
            scoreTitle = "Correct"
            consecutiveCorrect += 1
            consecutiveWrong = 0
            score += consecutiveCorrect * 5
        } else {
            scoreTitle = "Wrong"
            consecutiveWrong += 1
            consecutiveCorrect = 0
            score -= consecutiveWrong * 5
        }

        if currentQuestion == totalQuestions {
            showingFinalScore = true
        } else {
            showingScore = true
        }
    }

    func askQuestion() {
        if currentQuestion < totalQuestions {
            currentQuestion += 1
            countries.shuffle()
            correctAnswer = Int.random(in: 0...2)
        }
    }

    func saveScoreIfTop10() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let userScoresRef = db.collection("users").document(userId).collection("scores")

        // Fetch existing scores
        userScoresRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching scores: \(error.localizedDescription)")
                return
            }

            var scores: [(timestamp: Timestamp, score: Int)] = []

            snapshot?.documents.forEach { document in
                if let score = document.data()["score"] as? Int,
                   let timestamp = document.data()["timestamp"] as? Timestamp {
                    scores.append((timestamp: timestamp, score: score))
                }
            }

            // Sort scores in descending order
            scores.sort { $0.score > $1.score }

            if scores.count < 10 || score > scores.last!.score {
                // Add the new score
                let newScore = ["score": score, "timestamp": Timestamp(date: Date())] as [String : Any]

                userScoresRef.addDocument(data: newScore) { error in
                    if let error = error {
                        print("Error saving score: \(error.localizedDescription)")
                    } else {
                        print("Score saved successfully!")
                    }
                }

                // Keep only the top 10 scores
                if scores.count >= 10 {
                    let lowestScoreDoc = snapshot?.documents.last
                    lowestScoreDoc?.reference.delete { error in
                        if let error = error {
                            print("Error deleting score: \(error.localizedDescription)")
                        } else {
                            print("Lowest score removed to maintain top 10 scores.")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    GameView()
}
