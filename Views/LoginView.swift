import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    @AppStorage("IsLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("SavedFirstName") private var savedFirstName: String = ""
    
    @State private var navigateToHome = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Log In")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                // Email Field
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 40)
                
                // Password Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Log In Button
                Button(action: {
                    if validateCredentials() {
                        navigateToHome = true
                    }
                }) {
                    Text("Log In")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                }
                .disabled(email.isEmpty || password.isEmpty)
                
                Spacer()
            }
        }
        // Navigate to Home or Mood Check-in
        .fullScreenCover(isPresented: $navigateToHome) {
            if alreadyCheckedInToday() {
                HomePageView(firstName: savedFirstName)
            } else {
                MoodCheckInView(firstName: savedFirstName)
            }
        }
    }
    
    // MARK: - Validate Credentials
    func validateCredentials() -> Bool {
        if let user = UserDatabaseManager.getUser(email: email) {
            if user.password == password {
                savedFirstName = user.firstName
                isLoggedIn = true
                errorMessage = nil
                return true
            } else {
                errorMessage = "Incorrect password."
                return false
            }
        } else {
            errorMessage = "No account found for this email."
            return false
        }
    }
    
    // MARK: - Check if Already Checked In
    func alreadyCheckedInToday() -> Bool {
        let lastCheckInDate = UserDefaults.standard.object(forKey: "LastMoodCheckInDate") as? Date
        let calendar = Calendar.current
        return lastCheckInDate != nil && calendar.isDateInToday(lastCheckInDate!)
    }
}
