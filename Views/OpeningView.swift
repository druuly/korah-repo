import SwiftUI

struct OpeningView: View {
    @State private var fadeIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // LOGO
                    Image("monster")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150) // Adjust size as needed
                        .opacity(fadeIn ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.1), value: fadeIn)
                    
                    // Title
                    Text("Welcome to Korah")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(fadeIn ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.3), value: fadeIn)
                    
                    // Subtitle
                    Text("Your very own focus-buddy.")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color.purple)
                        .multilineTextAlignment(.center)
                        .opacity(fadeIn ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.5), value: fadeIn)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                        }
                        .opacity(fadeIn ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.7), value: fadeIn)
                        
                        NavigationLink(destination: CreateAccountView()) {
                            Text("Create Account")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple.opacity(0.8))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                        }
                        .opacity(fadeIn ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.9), value: fadeIn)
                    }
                    
                    Spacer()
                }
                .onAppear {
                    fadeIn = true
                }
            }
        }
    }
}

struct OpeningView_Previews: PreviewProvider {
    static var previews: some View {
        OpeningView()
    }
}
