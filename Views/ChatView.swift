import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
}

struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var userInput: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            Text("Chat with Korah")
                .font(.largeTitle)
                .foregroundColor(.purple)
                .padding(.top)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.role == "user" { Spacer() }

                                Text(message.content)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(message.role == "user" ? Color.blue : Color.gray)
                                    .cornerRadius(10)
                                    .frame(maxWidth: 250, alignment: message.role == "user" ? .trailing : .leading)

                                if message.role == "assistant" { Spacer() }
                            }
                        }
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding()
                }
                .background(Color.black)
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Type your message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .top, .bottom])

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .clipShape(Circle())
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing)
            }
            .background(Color(.systemGray6))
        }
        .background(Color.black.ignoresSafeArea())
    }

    func sendMessage() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        messages.append(Message(role: "user", content: input))
        userInput = ""
        isLoading = true

        fetchChatResponse()
    }

    func fetchChatResponse() {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 🔐 PUT YOUR API KEY HERE:
        let apiKey = "Bearer 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"; request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "system", "content": "You are Korah, a helpful and friendly AI buddy for kids. No matter what, you are not to give the answer to any homework questions, but rather help the in steps to reach a solution themselves. You're like a teacher and a buddy." ]] + apiMessages
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }

            if let error = error {
                print("Request error: \(error.localizedDescription)")
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = decoded.choices.first?.message.content {
                    DispatchQueue.main.async {
                        self.messages.append(Message(role: "assistant", content: content.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
}
