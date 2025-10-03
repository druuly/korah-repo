import SwiftUI
import Foundation
import UIKit

// AI-generated Study Guides using the same OpenAI API pattern as ChatView
struct StudyGuidesView: View {
    @State private var inputText: String = ""
    @State private var guideTitle: String = ""
    @State private var generatedMarkdown: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    // Library persistence
    @State private var savedGuides: [StudyGuide] = []
    private let saveKey = "StudyGuides"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Study Guide")
                            .font(.title2).bold()
                            .foregroundColor(.purple)
                        Text("Paste a large chunk of text (notes, article, chapter). We'll generate a concise study guide with key points, terms, and practice questions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Title
                    TextField("Optional title (e.g. Biology - Cells)", text: $guideTitle)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    // Paste Text
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $inputText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        if inputText.isEmpty {
                            Text("Paste source text here…")
                                .foregroundColor(.gray)
                                .padding(.top, 14)
                                .padding(.leading, 14)
                        }
                    }

                    // Generate Button
                    Button(action: generateStudyGuide) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isLoading ? "Generating…" : "Generate")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? Color.gray.opacity(0.5) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    
                    if !generatedMarkdown.isEmpty {
                        Button(action: generateStudyGuide) {
                            HStack {
                                if isLoading { ProgressView().tint(.white) }
                                Text(isLoading ? "Generating…" : "Generate Again").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLoading ? Color.gray.opacity(0.5) : Color.purple.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }

                    if let error = errorMessage, !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Preview
                    if !generatedMarkdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.purple)

                            Group {
                                if let attributed = try? AttributedString(markdown: generatedMarkdown) {
                                    Text(attributed)
                                        .foregroundColor(.white)
                                } else {
                                    Text(generatedMarkdown)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                Button(action: saveCurrentGuide) {
                                    Label("Save to Library", systemImage: "tray.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)

                                Button(action: copyToClipboard) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                    }

                    // Library
                    if !savedGuides.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Saved Guides")
                                .font(.headline)
                                .foregroundColor(.purple)
                            ForEach(savedGuides.sorted(by: { $0.createdAt > $1.createdAt })) { guide in
                                NavigationLink(destination: StudyGuideReaderView(guide: guide)) {
                                    VStack(alignment: .leading) {
                                        Text(guide.title.isEmpty ? "Untitled Guide" : guide.title)
                                            .foregroundColor(.white)
                                        Text(guide.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Study Guides (AI)")
            .background(Color.black.ignoresSafeArea())
        }
        .accentColor(.purple)
        .onAppear(perform: loadGuides)
    }

    // MARK: - Actions
    private func generateStudyGuide() {
        errorMessage = nil
        generatedMarkdown = ""
        isLoading = true

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 🔐 Uses the same API key pattern as ChatView
        let apiKey = "Bearer " // Put your key after Bearer
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        let systemPrompt = """
You are an expert study coach. Respond ONLY with valid GitHub‑flavored Markdown. Follow this template and rules EXACTLY:

TEMPLATE:
## Title
<short descriptive title>

## Key Takeaways
- <bullet 1>
- <bullet 2>
- <bullet 3>
- <bullet 4>
- <bullet 5>

## Terms
- <term>: <short definition>
- <term>: <short definition>
- <term>: <short definition>

## Summary
<3–5 sentences summary>

## Practice Questions
1. <question>
2. <question>
3. <question>
4. <question>
5. <question>

## Answers
1. <short answer>
2. <short answer>
3. <short answer>
4. <short answer>
5. <short answer>

RULES:
- Use exactly the headings shown above (## Title, ## Key Takeaways, ## Terms, ## Summary, ## Practice Questions, ## Answers).
- Use hyphen bullets "- " for lists. For nested bullets, indent by two spaces then "- ".
- Insert a blank line between paragraphs and before/after lists.
- Do NOT add any text before or after the template.
- Keep the tone clear, encouraging, and appropriate for kids aged 8–14.
"""

        let formatExample = """
## Title
Photosynthesis Basics

## Key Takeaways
- Plants use sunlight to convert water and carbon dioxide into glucose (sugar).
- Chlorophyll in leaves absorbs light energy.
- Oxygen is released as a by‑product of photosynthesis.
- Photosynthesis mostly happens in the chloroplasts of plant cells.
- Glucose provides energy for growth and repair.

## Terms
- Chlorophyll: Green pigment that captures light energy.
- Chloroplast: Cell part where photosynthesis happens.
- Glucose: A simple sugar that stores energy for the plant.

## Summary
Photosynthesis is how plants make their own food. Using sunlight, plants change water and carbon dioxide into glucose, which gives them energy. The process takes place in chloroplasts and uses chlorophyll to capture light. Oxygen is made and released into the air. This helps plants grow and also supplies animals and people with oxygen.

## Practice Questions
1. What does chlorophyll do?
2. Where does photosynthesis happen inside plant cells?
3. What gas do plants release during photosynthesis?
4. What two ingredients do plants need to make glucose?
5. Why is glucose important to the plant?

## Answers
1. It captures light energy from the sun.
2. In the chloroplasts.
3. Oxygen.
4. Water and carbon dioxide (plus sunlight energy).
5. It provides energy for the plant to grow and repair.
"""

        let userPrompt = """
        Source Text:\n\n\(inputText)
        """

        struct ChatMessage: Encodable { let role: String; let content: String }
        struct ChatRequest: Encodable {
            let model: String
            let temperature: Double
            let max_tokens: Int
            let messages: [ChatMessage]
            enum CodingKeys: String, CodingKey { case model, temperature, max_tokens = "max_tokens", messages }
        }

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: "Example input: A short paragraph about photosynthesis for kids."),
            ChatMessage(role: "assistant", content: formatExample),
            ChatMessage(role: "user", content: userPrompt)
        ]

        let chatBody = ChatRequest(model: "gpt-3.5-turbo", temperature: 0.1, max_tokens: 1400, messages: messages)
        request.httpBody = try? JSONEncoder().encode(chatBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }

            if let error = error {
                DispatchQueue.main.async { self.errorMessage = "Network error: \(error.localizedDescription)" }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data from server" }
                return
            }

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let message: String
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let err = dict["error"] as? [String: Any],
                   let msg = err["message"] as? String {
                    message = msg
                } else {
                    message = "HTTP Error \(http.statusCode). Check your API key."
                }
                DispatchQueue.main.async { self.errorMessage = message }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                DispatchQueue.main.async { self.generatedMarkdown = normalizeMarkdown(content) }
            } catch {
                let responseString = String(data: data, encoding: .utf8) ?? "(unreadable)"
                print("Decode error: \(error)\nRaw: \(responseString)")
                DispatchQueue.main.async { self.errorMessage = "Decode error. See console." }
            }
        }.resume()
    }

    private func normalizeMarkdown(_ md: String) -> String {
        // Normalize line endings
        var text = md.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        // Replace common bullet characters with hyphens
        text = text.replacingOccurrences(of: "•", with: "-")
                   .replacingOccurrences(of: "– ", with: "- ")
                   .replacingOccurrences(of: "— ", with: "- ")
        // Ensure blank line before list blocks and between different block types
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        for i in 0..<lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isListItem = trimmed.hasPrefix("- ") || trimmed.range(of: "^\\d+\\. ", options: .regularExpression) != nil || trimmed.hasPrefix("* ")
            if isListItem {
                if let last = result.last, !last.trimmingCharacters(in: .whitespaces).isEmpty {
                    result.append("")
                }
                // Convert asterisk bullets to hyphen
                if trimmed.hasPrefix("* ") {
                    let converted = line.replacingOccurrences(of: "* ", with: "- ")
                    result.append(converted)
                    continue
                }
            }
            result.append(line)
        }
        return result.joined(separator: "\n")
    }

    private func saveCurrentGuide() {
        guard !generatedMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let title = guideTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let new = StudyGuide(title: title, content: generatedMarkdown)
        savedGuides.append(new)
        persistGuides()
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = generatedMarkdown
    }

    // MARK: - Persistence
    private func loadGuides() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([StudyGuide].self, from: data) {
            savedGuides = decoded
        }
    }

    private func persistGuides() {
        if let encoded = try? JSONEncoder().encode(savedGuides) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}

struct StudyGuideReaderView: View {
    let guide: StudyGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !guide.title.isEmpty {
                    Text(guide.title)
                        .font(.title)
                        .bold()
                        .foregroundColor(.purple)
                }
                Group {
                    if let attributed = try? AttributedString(markdown: guide.content) {
                        Text(attributed)
                            .foregroundColor(.white)
                    } else {
                        Text(guide.content)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Study Guide")
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    StudyGuidesView()
}
