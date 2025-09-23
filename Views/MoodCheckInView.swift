import SwiftUI

struct MoodCheckInView: View {
    @AppStorage("UserMood") private var userMood: String = ""
    @State private var navigateToHome = false
    var firstName: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Hi \(firstName)! 👋")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("How are you feeling today?")
                    .font(.title)
                    .foregroundColor(.purple)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 20) {
                    Button(action: {
                        userMood = "🟢"
                        UserDefaults.standard.set(Date(), forKey: "LastMoodCheckInDate") // Save check-in date
                        navigateToHome = true
                    }) {
                        Text("🟢 Very focused, ready to go")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        userMood = "🟡"
                        UserDefaults.standard.set(Date(), forKey: "LastMoodCheckInDate") // Save check-in date
                        navigateToHome = true
                    }) {
                        Text("🟡 I feel okay, somewhere near the middle")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        userMood = "🔴"
                        UserDefaults.standard.set(Date(), forKey: "LastMoodCheckInDate") // Save check-in date
                        navigateToHome = true
                    }) {
                        Text("🔴 Not very focused, not good")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $navigateToHome) {
            HomePageView(firstName: firstName)
        }
    }
}
