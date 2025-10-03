import Foundation

/// A single flashcard containing a front (question/prompt) and back (answer).
struct Flashcard: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var front: String
    var back: String
}

/// A collection of flashcards grouped into a named set that the user can study.
struct FlashcardSet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var cards: [Flashcard] = []
    var createdAt: Date = Date()
}

extension FlashcardSet {
    /// Sample data for previews and testing.
    static let sample: FlashcardSet = FlashcardSet(
        title: "Spanish Basics",
        cards: [
            Flashcard(front: "Hola", back: "Hello"),
            Flashcard(front: "Gracias", back: "Thank you"),
            Flashcard(front: "Adiós", back: "Goodbye")
        ]
    )

    /// A couple of sets for list previews.
    static let samples: [FlashcardSet] = [
        .sample,
        FlashcardSet(title: "Math Formulas", cards: [
            Flashcard(front: "Area of circle", back: "πr²"),
            Flashcard(front: "Quadratic Formula", back: "x = (-b ± √(b²-4ac)) / 2a")
        ])
    ]
}
