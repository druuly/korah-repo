import SwiftUI

struct RecentStudyItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let kind: String
    let createdAt: Date
    
    static let flashcardsKind = "Flashcards"
    static let studyGuideKind = "Study Guide"
    static let practiceTestKind = "Practice Test"
}

struct HomePageView: View {
    var firstName: String
    @AppStorage("UserMood") private var userMood: String = "" // Mood emoji storage
    @State private var showMoodPicker = false // For mood picker sheet
    @State private var tasks: [Task] = [] // Load upcoming tasks
    @State private var selectedTab = 0 // Track selected tab
    @State private var recentStudyItems: [RecentStudyItem] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 🏠 Home Tab
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    Text("Hello, \(firstName)! 👋")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    // 🗓 Upcoming Tasks Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Upcoming Tasks")
                                .font(.title3)
                                .foregroundColor(.purple)
                                .bold()
                            
                            Spacer()
                            
                            // Mood Emoji Button
                            Button(action: {
                                showMoodPicker = true
                            }) {
                                Text(userMood)
                                    .font(.largeTitle)
                            }
                        }
                        
                        if tasks.isEmpty {
                            Text("No upcoming tasks.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        } else {
                            ForEach(tasks.prefix(3)) { task in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    if !task.description.isEmpty {
                                        Text(task.description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // 📚 Study it again Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Study it again.")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .bold()
                            .padding(.horizontal)
                        
                        if recentStudyItems.isEmpty {
                            Text("No recent study items.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding(.horizontal)
                        } else {
                            ForEach(recentStudyItems.prefix(3)) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(item.kind)
                                            .font(.caption2)
                                            .bold()
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.2))
                                            .foregroundColor(.purple)
                                            .cornerRadius(8)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        
                        Button(action: {
                            selectedTab = 4
                        }) {
                            Text("Go to Study")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // 💬 Chat Section
                    VStack(spacing: 10) {
                        Text("Start a new chat with Korah")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .bold()
                        
                        Button(action: {
                            selectedTab = 2 // Switch to Chat tab
                        }) {
                            Text("Chat Now")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .background(Color.black.ignoresSafeArea())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            .onAppear {
                loadTasks()
                loadRecentStudy()
            }
            
            // ✅ Tasks Tab
            ToDoListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)
            
            // ✅ Chat Tab
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(2)
            
            // 🍅 Pomodoro Timer Tab
            PomodoroTimerView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
                .tag(3)
            
            // Study
            StudyHomeView()
                .tabItem {
                    Label("Study", systemImage: "book.closed")
                }
                .tag(4)
        }
        .accentColor(.purple)
        // Mood Picker Sheet
        .sheet(isPresented: $showMoodPicker) {
            moodPickerSheet
        }
    }
    
    // MARK: - Load Tasks
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "SavedTasks"),
           let savedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = savedTasks.sorted { $0.dueDate < $1.dueDate }
        }
    }
    
    // MARK: - Mood Picker Sheet
    var moodPickerSheet: some View {
        VStack(spacing: 20) {
            Text("Update Your Mood")
                .font(.title)
                .foregroundColor(.purple)
                .padding()
            
            Button(action: {
                userMood = "🟢"
                UserDefaults.standard.set(Date(), forKey: "LastMoodCheckInDate")
                showMoodPicker = false
            }) {
                Text("🟢 Very focused, ready to go")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            
            Button(action: {
                userMood = "🟡"
                UserDefaults.standard.set(Date(), forKey: "LastMoodCheckInDate")
                showMoodPicker = false
            }) {
                Text("🟡 I feel okay, somewhere near the middle")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(12)
            }
            
            Button(action: {
                userMood = "🔴"
                UserDefaults.standard.set(Date(), forKey: "LastMoodCheckInDate")
                showMoodPicker = false
            }) {
                Text("🔴 Not very focused, not good")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

extension HomePageView {
    func loadRecentStudy() {
        var allItems: [RecentStudyItem] = []
        let decoder = JSONDecoder()
        
        // FlashcardSets
        if let flashcardData = UserDefaults.standard.data(forKey: "FlashcardSets"),
           let flashcardSets = try? decoder.decode([FlashcardSet].self, from: flashcardData) {
            let flashcardsItems = flashcardSets.map {
                RecentStudyItem(id: $0.id, title: $0.title, kind: RecentStudyItem.flashcardsKind, createdAt: $0.createdAt)
            }
            allItems.append(contentsOf: flashcardsItems)
        }
        
        // StudyGuides
        if let guidesData = UserDefaults.standard.data(forKey: "StudyGuides"),
           let studyGuides = try? decoder.decode([StudyGuide].self, from: guidesData) {
            let guideItems = studyGuides.map {
                RecentStudyItem(id: $0.id, title: $0.title, kind: RecentStudyItem.studyGuideKind, createdAt: $0.createdAt)
            }
            allItems.append(contentsOf: guideItems)
        }
        
        // PracticeTests
        if let testsData = UserDefaults.standard.data(forKey: "PracticeTests"),
           let practiceTests = try? decoder.decode([PracticeTest].self, from: testsData) {
            let testItems = practiceTests.map {
                RecentStudyItem(id: $0.id, title: $0.title, kind: RecentStudyItem.practiceTestKind, createdAt: $0.createdAt)
            }
            allItems.append(contentsOf: testItems)
        }
        
        recentStudyItems = allItems.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3).map { $0 }
    }
}
