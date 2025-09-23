import SwiftUI

struct ToDoListView: View {
    @State private var tasks: [Task] = []
    @State private var showingAddTask = false
    @State private var editingTask: Task? = nil
    @State private var taskToDelete: Task? = nil
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if tasks.isEmpty {
                    Text("No tasks yet. Add one!")
                        .foregroundColor(.gray)
                        .font(.title3) // Slightly bigger empty state text
                        .padding()
                } else {
                    List {
                        ForEach(tasks) { task in
                            Button(action: {
                                editingTask = task // Open Edit sheet
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        // Task Title with Difficulty
                                                                                HStack {
                                                                                    Text(task.title)
                                                                                        .font(.title3) // Bigger title
                                                                                        .fontWeight(.semibold)
                                                                                    
                                                                                    Spacer()
                                                                                    
                                                                                    // Difficulty Badge
                                                                                    HStack(spacing: 4) {
                                                                                        Text(task.difficulty.emoji)
                                                                                        Text(task.difficulty.rawValue)
                                                                                            .font(.caption)
                                                                                            .fontWeight(.medium)
                                                                                    }
                                                                                    .padding(.horizontal, 8)
                                                                                    .padding(.vertical, 4)
                                                                                    .background(Color.gray.opacity(0.2))
                                                                                    .cornerRadius(8)
                                                                                }
                                        
                                        // Task Description (if any)
                                        if !task.description.isEmpty {
                                            Text(task.description)
                                                .font(.body) // Slightly larger body text
                                                .foregroundColor(.gray)
                                        }
                                        
                                        // Due Date
                                        Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.callout) // Slightly larger due date
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Spacer()
                                    
                                    // Delete Button
                                    Button(action: {
                                        taskToDelete = task // Show confirmation alert
                                        showDeleteConfirmation = true
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                    }
                                    .buttonStyle(BorderlessButtonStyle()) // Allow button inside list row
                                }
                                .padding(.vertical, 6) // Slightly taller rows
                            }
                            .buttonStyle(PlainButtonStyle()) // Prevent row highlight
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                Button(action: {
                    showingAddTask = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Your Tasks")
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(tasks: $tasks)
        }
        .sheet(item: $editingTask) { task in
            EditTaskView(task: task, tasks: $tasks)
        }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    deleteTask(task)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let task = taskToDelete {
                Text("Are you sure you want to delete \"\(task.title)\"?")
            }
        }
        .onAppear {
            loadTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "SavedTasks")
        }
    }
    
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "SavedTasks"),
           let savedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = savedTasks
        }
    }
}
