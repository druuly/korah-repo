import SwiftUI

struct StudyHomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StudyCard(destination: FlashcardsView(), title: "Flashcard Sets", systemImage: "rectangle.stack")
                StudyCard(destination: StudyGuidesView(), title: "Study Guides", systemImage: "book.closed")
                StudyCard(destination: PracticeTestsView(), title: "Practice Tests", systemImage: "doc.text.magnifyingglass")
                StudyCard(destination: AIPracticeTestGeneratorView(), title: "AI from Flashcards", systemImage: "wand.and.stars")
                Spacer()
            }
            .padding()
            .navigationTitle("Study Hub")
            .background(Color.black)
        }
        .tint(.purple)
        .background(Color.black.ignoresSafeArea())
    }
}

struct StudyCard<Destination: View>: View {
    let destination: Destination
    let title: String
    let systemImage: String

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 32)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StudyHomeView()
}
