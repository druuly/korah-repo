import Foundation

struct StudyGuide: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

extension StudyGuide {
    static let sampleData: [StudyGuide] = [
        StudyGuide(title: "Swift Basics", content: "Learn about variables, constants, and basic data types in Swift."),
        StudyGuide(title: "Protocols and Extensions", content: "Understand how protocols define interfaces and how extensions add functionality."),
        StudyGuide(title: "SwiftUI Introduction", content: "Discover how to build UI declaratively using SwiftUI framework.")
    ]
}

struct PracticeTestQuestion: Identifiable, Codable, Equatable {
    var id: UUID
    var prompt: String
    var options: [String]
    var correctIndex: Int

    init(id: UUID = UUID(), prompt: String, options: [String], correctIndex: Int) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
    }
}

struct PracticeTest: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var questions: [PracticeTestQuestion]
    var createdAt: Date

    init(id: UUID = UUID(), title: String, questions: [PracticeTestQuestion], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.questions = questions
        self.createdAt = createdAt
    }
}

extension PracticeTest {
    static let sampleData: [PracticeTest] = [
        PracticeTest(
            title: "Swift Basics Test",
            questions: [
                PracticeTestQuestion(
                    prompt: "Which keyword declares a constant in Swift?",
                    options: ["var", "let", "const", "final"],
                    correctIndex: 1
                ),
                PracticeTestQuestion(
                    prompt: "What is the type of 3.14?",
                    options: ["Int", "Double", "String", "Float"],
                    correctIndex: 1
                )
            ]
        ),
        PracticeTest(
            title: "SwiftUI Fundamentals",
            questions: [
                PracticeTestQuestion(
                    prompt: "Which protocol must a SwiftUI view conform to?",
                    options: ["UIViewController", "View", "Delegate", "ObservableObject"],
                    correctIndex: 1
                ),
                PracticeTestQuestion(
                    prompt: "What modifier is used to add padding to a view?",
                    options: [".frame()", ".padding()", ".background()", ".cornerRadius()"],
                    correctIndex: 1
                ),
                PracticeTestQuestion(
                    prompt: "How do you declare a state variable in SwiftUI?",
                    options: ["@State var", "var", "let", "@Published var"],
                    correctIndex: 0
                )
            ]
        )
    ]
}
