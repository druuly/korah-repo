import SwiftUI

// MARK: - Root Flashcards View
struct FlashcardsView: View {
    @State private var sets: [FlashcardSet] = []
    @State private var showingAddSet = false
    @State private var newSetTitle: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                content
            }
            .navigationTitle("Flashcards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSet = true }) {
                        Label("Add Set", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .onAppear(perform: loadSets)
        .sheet(isPresented: $showingAddSet) { addSetSheet }
    }

    @ViewBuilder
    private var content: some View {
        if sets.isEmpty {
            VStack(spacing: 16) {
                Text("No flashcard sets yet.")
                    .foregroundColor(.gray)
                Button(action: { showingAddSet = true }) {
                    Text("Create your first set")
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
        } else {
            List {
                ForEach(sets) { set in
                    NavigationLink(destination: FlashcardSetDetailView(set: set, onSave: updateSet, onDelete: deleteSet)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(set.title)
                                .font(.headline)
                            Text("\(set.cards.count) cards")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                }
                .onDelete(perform: delete)
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Add Set Sheet
    private var addSetSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Set Title")) {
                    TextField("e.g. Biology - Cell Parts", text: $newSetTitle)
                }
            }
            .navigationTitle("New Set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddSet = false; newSetTitle = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addSet() }
                        .disabled(newSetTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - CRUD & Persistence
    private func addSet() {
        let title = newSetTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let new = FlashcardSet(title: title, cards: [])
        sets.append(new)
        saveSets()
        newSetTitle = ""
        showingAddSet = false
    }

    private func delete(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
        saveSets()
    }

    private func updateSet(_ updated: FlashcardSet) {
        if let idx = sets.firstIndex(where: { $0.id == updated.id }) {
            sets[idx] = updated
            saveSets()
        }
    }

    private func deleteSet(_ set: FlashcardSet) {
        sets.removeAll { $0.id == set.id }
        saveSets()
    }

    private func saveSets() {
        if let data = try? JSONEncoder().encode(sets) {
            UserDefaults.standard.set(data, forKey: "FlashcardSets")
        }
    }

    private func loadSets() {
        if let data = UserDefaults.standard.data(forKey: "FlashcardSets"),
           let decoded = try? JSONDecoder().decode([FlashcardSet].self, from: data) {
            sets = decoded
        } else {
            sets = []
        }
    }
}

// MARK: - Set Detail (Add/Edit Cards)
struct FlashcardSetDetailView: View {
    @State var set: FlashcardSet
    var onSave: (FlashcardSet) -> Void
    var onDelete: (FlashcardSet) -> Void

    @State private var showingAddCard = false
    @State private var newFront = ""
    @State private var newBack = ""

    var body: some View {
        List {
            Section(header: Text("Cards")) {
                if set.cards.isEmpty {
                    Text("No cards yet. Add one!")
                        .foregroundColor(.gray)
                } else {
                    ForEach(set.cards) { card in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.front)
                                .font(.headline)
                            Text(card.back)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .onDelete(perform: deleteCards)
                }
            }
        }
        .navigationTitle(set.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingAddCard = true }) {
                    Label("Add Card", systemImage: "plus")
                }
                NavigationLink(destination: StudySessionView(set: set)) {
                    Label("Study", systemImage: "rectangle.stack.person.crop")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) { onDelete(set) } label: {
                    Label("Delete Set", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) { addCardSheet }
        .onDisappear { onSave(set) }
    }

    private var addCardSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Front")) {
                    TextField("Question / Prompt", text: $newFront)
                }
                Section(header: Text("Back")) {
                    TextField("Answer", text: $newBack)
                }
            }
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddCard = false; newFront = ""; newBack = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addCard() }
                        .disabled(newFront.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newBack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addCard() {
        let f = newFront.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = newBack.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else { return }
        set.cards.append(Flashcard(front: f, back: b))
        newFront = ""
        newBack = ""
        showingAddCard = false
    }

    private func deleteCards(at offsets: IndexSet) {
        set.cards.remove(atOffsets: offsets)
    }
}

// MARK: - Study Mode (Flip Through Cards)
struct StudySessionView: View {
    let set: FlashcardSet
    @State private var index: Int = 0
    @State private var showBack: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            if set.cards.isEmpty {
                Text("No cards to study.")
                    .foregroundColor(.gray)
            } else {
                Text("Card \(index + 1) of \(set.cards.count)")
                    .foregroundColor(.purple)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .overlay(
                            VStack(spacing: 12) {
                                Text(showBack ? set.cards[index].back : set.cards[index].front)
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .padding()

                                Text(showBack ? "Back" : "Front")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        )
                        .padding(.horizontal)
                        .onTapGesture { withAnimation { showBack.toggle() } }
                }

                HStack(spacing: 16) {
                    Button(action: prev) {
                        Label("Back", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { withAnimation { showBack.toggle() } }) {
                        Text("Flip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: next) {
                        Label("Next", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .tint(.purple)
                .padding(.horizontal)
            }
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Study")
    }

    private func next() {
        guard !set.cards.isEmpty else { return }
        if index < set.cards.count - 1 {
            index += 1
            showBack = false
        }
    }

    private func prev() {
        guard !set.cards.isEmpty else { return }
        if index > 0 {
            index -= 1
            showBack = false
        }
    }
}

#Preview {
    NavigationStack { FlashcardsView() }
}
