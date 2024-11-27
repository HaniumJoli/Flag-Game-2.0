import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    @State private var isShowingLogin = true
    
    var body: some View {
        if isShowingLogin {
            LoginView(switchToRegister: { isShowingLogin = false })
        } else {
            RegisterView(switchToLogin: { isShowingLogin = true })
        }
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    let switchToRegister: () -> Void
    
    var body: some View {
        ZStack {
            RadialGradient(stops: [
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)
            ], center: .top, startRadius: 200, endRadius: 700)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Flag Game")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.bottom, 40)
                
                Text("Login")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: login) {
                    Text("Login")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: loginWithGithub) {
                    Text("Login with GitHub")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: switchToRegister) {
                    Text("Don't have an account? Register")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
    
    private func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = nil
                print("User logged in successfully")
            }
        }
    }
    
    private func loginWithGithub() {
        let provider = OAuthProvider(providerID: "github.com")
                
                provider.getCredentialWith(nil) { credential, error in
                    if let error = error {
                        print("GitHub login failed: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let credential = credential else { return }
                    
                    Auth.auth().signIn(with: credential) { result, error in
                        if let error = error {
                            print("Firebase sign-in failed: \(error.localizedDescription)")
                            return
                        }
                    
                        print("User signed in with GitHub")
                    }
                }
            }
        
}

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    let switchToLogin: () -> Void
    
    var body: some View {
        ZStack {
            RadialGradient(stops: [
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)
            ], center: .top, startRadius: 200, endRadius: 700)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Flag Game")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.bottom, 40)
                
                Text("Register")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: register) {
                    Text("Register")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: registerWithGithub) {
                    Text("Register with GitHub")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: switchToLogin) {
                    Text("Already registered? Login")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
    
    private func register() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                errorMessage = nil
                saveUserToFirestore(user: user)
                print("User registered successfully")
            }
        }
    }
    
    private func saveUserToFirestore(user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "email": user.email ?? "",
            "name": user.displayName ?? "GitHub User",
            "githubUID": user.uid,
            "profilePhotoURL": user.photoURL?.absoluteString ?? "",
            "githubName": user.displayName ?? ""
        ]) { error in
            if let error = error {
                print("Error saving user to Firestore: \(error.localizedDescription)")
            } else {
                print("User registered with GitHub successfully.")
            }
        }
    }
    
    private func registerWithGithub() {
        let provider = OAuthProvider(providerID: "github.com")
        
        provider.getCredentialWith(nil) { credential, error in
            if let error = error {
                print("GitHub login failed: \(error.localizedDescription)")
                return
            }
            
            guard let credential = credential else {
                print("Failed to get GitHub credentials.")
                return
            }
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase sign-in failed: \(error.localizedDescription)")
                    return
                }
                
                if let user = result?.user {
                    self.checkAndMergeAccount(user: user)
                }
            }
        }
    }

    private func checkAndMergeAccount(user: FirebaseAuth.User) {
        guard let email = user.email else {
            print("User does not have an email associated with the GitHub account.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking Firestore: \(error.localizedDescription)")
                return
            }
            
            if let document = snapshot?.documents.first {
                print("User with this email exists. Merging accounts.")
                
                let userID = document.documentID
                db.collection("users").document(userID).updateData([
                    "githubUID": user.uid,
                    "profilePhotoURL": user.photoURL?.absoluteString ?? "",
                    "githubName": user.displayName ?? ""
                ]) { error in
                    if let error = error {
                        print("Error merging account: \(error.localizedDescription)")
                    } else {
                        print("Accounts merged successfully.")
                    }
                }
            } else {
                print("No user with this email. Creating a new account.")
                self.saveUserToFirestore(user: user)
            }
        }
    }
}

#Preview {
    AuthView()
}
