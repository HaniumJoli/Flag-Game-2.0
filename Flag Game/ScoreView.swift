
import SwiftUI

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ScoreView: View {
    @State private var scores: [(score: Int, timestamp: Date)] = []
    @State private var loading = true

    var body: some View {
        ZStack {
            RadialGradient(stops: [
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)
            ], center: .top, startRadius: 200, endRadius: 700)
                .ignoresSafeArea()

            VStack {
                if loading {
                    ProgressView("Loading High Scores...")
                        .foregroundStyle(.white)
                } else if scores.isEmpty {
                    Text("No high scores available.")
                        .foregroundStyle(.white)
                        .font(.title)
                } else {
                    List {
                        ForEach(scores, id: \.timestamp) { score in
                            HStack {
                                Text("Score: \(score.score)")
                                Spacer()
                                Text(score.timestamp, style: .date)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .onAppear(perform: fetch)
        }
    }

    private func fetch() {
        guard let user = Auth.auth().currentUser else {
            loading = false
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("scores")
            .order(by: "score", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                loading = false
                if let error = error {
                    print("Error fetching scores: \(error.localizedDescription)")
                    return
                }
                scores = snapshot?.documents.compactMap { document in
                    guard let score = document.data()["score"] as? Int,
                          let timestamp = document.data()["timestamp"] as? Timestamp else { return nil }
                    return (score: score, timestamp: timestamp.dateValue())
                } ?? []
            }
    }
}


#Preview {
    ScoreView()
}
