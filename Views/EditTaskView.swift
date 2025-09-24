import SwiftUI

struct EditTaskView: View {
    var task: Task
    @Binding var tasks: [Task]
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var difficulty: TaskDifficulty
    
    init(task: Task, tasks: Binding<[Task]>) {
        self.task = task
        self._tasks = tasks
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._dueDate = State(initialValue: task.dueDate)
        self._difficulty = State(initialValue: task.difficulty)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Edit Task Info")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Edit Due Date")) {
                    DatePicker("Select Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Edit Difficulty")) {
                    Picker("Difficulty Level", selection: $difficulty) {
                        ForEach(TaskDifficulty.allCases, id: \.self) { level in
                            HStack {
                                Text(level.emoji)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveChanges() {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = title
            tasks[index].description = description
            tasks[index].dueDate = dueDate
            tasks[index].difficulty = difficulty
            saveTasksToUserDefaults()
        }
    }
    
    func saveTasksToUserDefaults() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "SavedTasks")
        }
    }
}
