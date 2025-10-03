import SwiftUI

// Uses PracticeTest and PracticeTestQuestion from StudyModels.swift
final class PracticeTestsStore: ObservableObject {
    @Published var practiceTests: [PracticeTest] = [] {
        didSet { save() }
    }
    private let key = "PracticeTests"

    init() { load() }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PracticeTest].self, from: data) {
            practiceTests = decoded
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(practiceTests) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

struct PracticeTestsView: View {
    @StateObject private var store = PracticeTestsStore()
    @State private var newTestTitle = ""
    @State private var showingAdd = false
    @State private var showingAI = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Add New Test")) {
                    HStack {
                        TextField("Title", text: $newTestTitle)
                        Button(action: addTest) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(newTestTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .purple)
                        }
                        .disabled(newTestTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section {
                    ForEach(store.practiceTests) { test in
                        NavigationLink(destination: PracticeTestDetailView(practiceTest: binding(for: test))) {
                            VStack(alignment: .leading) {
                                Text(test.title)
                                Text(test.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTests)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Practice Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton().tint(.purple)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) { Image(systemName: "plus") }
                    Button(action: { showingAI = true }) { Image(systemName: "wand.and.stars") }
                }
            }
        }
        .preferredColorScheme(.dark)
        .accentColor(.purple)
        .sheet(isPresented: $showingAI) {
            AIPracticeTestGeneratorView()
        }
    }

    private func binding(for test: PracticeTest) -> Binding<PracticeTest> {
        guard let index = store.practiceTests.firstIndex(where: { $0.id == test.id }) else { fatalError("Test not found") }
        return $store.practiceTests[index]
    }

    private func addTest() {
        let title = newTestTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let new = PracticeTest(title: title, questions: [])
        store.practiceTests.append(new)
        newTestTitle = ""
    }

    private func deleteTests(at offsets: IndexSet) {
        store.practiceTests.remove(atOffsets: offsets)
    }
}

struct PracticeTestDetailView: View {
    @Binding var practiceTest: PracticeTest
    @State private var showingAddQuestionSheet = false
    @State private var editingQuestion: PracticeTestQuestion? = nil

    var body: some View {
        VStack {
            if practiceTest.questions.isEmpty {
                Text("No questions added yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(practiceTest.questions) { q in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(q.prompt).font(.headline)
                            ForEach(q.options.indices, id: \.self) { idx in
                                let option = q.options[idx]
                                HStack {
                                    if idx == q.correctIndex {
                                        Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                                    }
                                    Text(option)
                                }
                                .font(.subheadline)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingQuestion = q }
                    }
                    .onDelete(perform: deleteQuestions)
                }
            }
            Spacer()
            NavigationLink(destination: TakePracticeTestView(practiceTest: $practiceTest)) {
                Text("Start Test")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(practiceTest.questions.isEmpty ? Color.gray.opacity(0.5) : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(practiceTest.questions.isEmpty)
        }
        .navigationTitle(practiceTest.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddQuestionSheet = true }) { Image(systemName: "plus") }
                .tint(.purple)
            }
        }
        .sheet(item: $editingQuestion) { question in
            QuestionEditView(question: question) { edited in
                if let idx = practiceTest.questions.firstIndex(where: { $0.id == edited.id }) {
                    practiceTest.questions[idx] = edited
                }
                editingQuestion = nil
            } onCancel: {
                editingQuestion = nil
            }
            .accentColor(.purple)
        }
        .sheet(isPresented: $showingAddQuestionSheet) {
            QuestionEditView(question: PracticeTestQuestion(prompt: "", options: ["", "", "", ""], correctIndex: 0)) { newQ in
                practiceTest.questions.append(newQ)
                showingAddQuestionSheet = false
            } onCancel: {
                showingAddQuestionSheet = false
            }
            .accentColor(.purple)
        }
    }

    private func deleteQuestions(at offsets: IndexSet) {
        practiceTest.questions.remove(atOffsets: offsets)
    }
}

struct QuestionEditView: View {
    @State var question: PracticeTestQuestion
    let onSave: (PracticeTestQuestion) -> Void
    let onCancel: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Question")) {
                    TextField("Question text", text: $question.prompt)
                        .textInputAutocapitalization(.sentences)
                }
                Section(header: Text("Options (exactly 4)")) {
                    ForEach(0..<question.options.count, id: \.self) { i in
                        TextField("Option \(i+1)", text: Binding(
                            get: { question.options[i] },
                            set: { question.options[i] = $0 }
                        ))
                        .textInputAutocapitalization(.sentences)
                    }
                }
                Section(header: Text("Correct Answer")) {
                    Picker("Correct option", selection: $question.correctIndex) {
                        ForEach(0..<question.options.count, id: \.self) { i in
                            Text(question.options[i].isEmpty ? "Option \(i+1)" : question.options[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if let errorMessage = errorMessage {
                    Section { Text(errorMessage).foregroundColor(.red) }
                }
            }
            .navigationTitle("Question")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
            }
        }
    }

    private var canSave: Bool {
        !question.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        question.options.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } &&
        (0..<question.options.count).contains(question.correctIndex)
    }

    private func save() {
        guard canSave else {
            errorMessage = "Please ensure question and all options are filled, and correct answer is selected."
            return
        }
        onSave(question)
    }
}

struct TakePracticeTestView: View {
    @Binding var practiceTest: PracticeTest

    @State private var currentQuestionIndex = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var score = 0
    @State private var showResult = false

    var body: some View {
        VStack {
            if showResult {
                VStack(spacing: 20) {
                    Text("Test Completed!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.purple)
                    Text("Score: \(score) / \(practiceTest.questions.count)")
                        .font(.title2)
                    Button("Retake Test") { resetTest() }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                }
                .padding()
                Spacer()
            } else {
                if currentQuestionIndex < practiceTest.questions.count {
                    let question = practiceTest.questions[currentQuestionIndex]
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Question \(currentQuestionIndex + 1) of \(practiceTest.questions.count)")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Text(question.prompt)
                            .font(.title2)
                            .bold()
                        ForEach(question.options.indices, id: \.self) { idx in
                            let option = question.options[idx]
                            Button(action: { selectedOptionIndex = idx }) {
                                HStack {
                                    Image(systemName: selectedOptionIndex == idx ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(selectedOptionIndex == idx ? .purple : .secondary)
                                    Text(option)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedOptionIndex == idx ? Color.purple : Color.secondary.opacity(0.5), lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        Button(action: submitAnswer) {
                            Text("Submit Answer")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedOptionIndex == nil ? Color.gray.opacity(0.5) : Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(selectedOptionIndex == nil)
                    }
                    .padding()
                } else {
                    Spacer()
                }
            }
        }
        .navigationTitle(practiceTest.title)
        .preferredColorScheme(.dark)
        .accentColor(.purple)
    }

    private func submitAnswer() {
        guard let selected = selectedOptionIndex, currentQuestionIndex < practiceTest.questions.count else { return }
        let correct = practiceTest.questions[currentQuestionIndex].correctIndex
        if selected == correct { score += 1 }
        selectedOptionIndex = nil
        if currentQuestionIndex + 1 == practiceTest.questions.count { showResult = true } else { currentQuestionIndex += 1 }
    }

    private func resetTest() {
        score = 0
        currentQuestionIndex = 0
        selectedOptionIndex = nil
        showResult = false
    }
}

#Preview {
    NavigationStack { PracticeTestsView() }
}
