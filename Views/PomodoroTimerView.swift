import SwiftUI
import Foundation
import UserNotifications
import UIKit   // for UIApplication.openSettingsURLString

#if canImport(FamilyControls)
import FamilyControls
#endif

#if canImport(ManagedSettings)
import ManagedSettings
#endif

#if canImport(DeviceActivity)
import DeviceActivity
#endif

struct PomodoroTimerView: View {
    @State private var timeRemaining = 600 // 10 minutes in seconds
    @State private var isTimerActive = false
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var showingBlockingAlert = false
    @State private var focusMode = false
    @State private var showingAppSelection = false
    #if canImport(FamilyControls)
    @State private var selectedApps = FamilyActivitySelection()
    #endif
    @State private var showingPermissionAlert = false
    @State private var hasScreenTimePermission = false
    @State private var permissionStatus: String = "Checking permissions..."
    
    #if canImport(ManagedSettings)
    private let store = ManagedSettingsStore()
    #endif
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("🍅 Pomodoro Timer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Timer Display
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.purple.opacity(0.3), lineWidth: 12)
                            .frame(width: 250, height: 250)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(1 - Double(timeRemaining) / 600.0))
                            .stroke(Color.purple, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 250, height: 250)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeRemaining)
                        
                        VStack {
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Text(isTimerRunning ? "Focus Time!" : "Ready to Focus")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    // Control Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            if isTimerRunning {
                                stopTimer()
                            } else {
                                startTimer()
                            }
                        }) {
                            Text(isTimerRunning ? "Stop" : "Start")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 100, height: 50)
                                .background(isTimerRunning ? Color.red : Color.green)
                                .cornerRadius(25)
                        }
                        
                        Button(action: resetTimer) {
                            Text("Reset")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 100, height: 50)
                                .background(Color.gray)
                                .cornerRadius(25)
                        }
                    }
                }
                
                // Focus Mode Section
                VStack(spacing: 15) {
                    Text("🛡️ App Blocking")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    // Permission Status
                    Text(permissionStatus)
                        .font(.subheadline)
                        .foregroundColor(hasScreenTimePermission ? .green : .orange)
                        .multilineTextAlignment(.center)
                    
                    // Permission Button
                    if !hasScreenTimePermission {
                        Button(action: {
                            requestScreenTimePermission()
                        }) {
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("Grant Screen Time Permissions")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    } else {
                        // App Selection Button
                        Button(action: {
                            showingAppSelection = true
                        }) {
                            HStack {
                                Image(systemName: "apps.iphone")
                                #if canImport(FamilyControls)
                                Text(selectedApps.applicationTokens.isEmpty ? "Select Apps to Block" : "\(selectedApps.applicationTokens.count + selectedApps.categoryTokens.count) Apps Selected")
                                #else
                                Text("Select Apps to Block")
                                #endif
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        
                        // Focus Mode Toggle
                        Toggle("Enable App Blocking During Timer", isOn: $focusMode)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    #if canImport(FamilyControls)
                    if hasScreenTimePermission && focusMode && (!selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty) {
                        Text("✅ Selected apps will be blocked during timer sessions")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    } else if hasScreenTimePermission && focusMode {
                        Text("⚠️ Please select apps to block for focus mode to work")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    #else
                    if hasScreenTimePermission && focusMode {
                        Text("ℹ️ Screen Time features not available in this environment")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    #endif
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            requestNotificationPermission()
            checkScreenTimePermissionStatus()
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $showingAppSelection, selection: $selectedApps)
        #endif
        .alert("Timer Complete!", isPresented: $showingBlockingAlert) {
            Button("OK") {
                resetTimer()
            }
        } message: {
            Text("🎆 Congratulations! You've completed your 10-minute focus session. Great job staying focused!")
        }
        .alert("Screen Time Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Screen Time permissions are required to block apps during focus sessions. Please enable Family Controls in Settings > Screen Time > Family Controls.")
        }
    }
    
    // MARK: - Timer Functions
    func startTimer() {
        guard !isTimerRunning else { return }
        
        isTimerRunning = true
        isTimerActive = true
        
        // Apply app blocking if focus mode is enabled and permissions are granted
        if focusMode && hasScreenTimePermission {
            applyAppRestrictions()
            scheduleNotificationReminder()
        } else if focusMode {
            scheduleNotificationReminder()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Timer completed
                stopTimer()
                showCompletionFeedback()
            }
        }
    }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        
        // Remove app restrictions if they were applied
        if focusMode && hasScreenTimePermission {
            removeAppRestrictions()
        }
        
        // Cancel any pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func resetTimer() {
        stopTimer()
        timeRemaining = 600
        isTimerActive = false
    }
    
    // MARK: - Screen Time Permission Functions
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func checkScreenTimePermissionStatus() {
        #if canImport(FamilyControls)
        if #available(iOS 15.0, *) {
            _Concurrency.Task {
                do {
                    // Request (returns Void), then read status
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let status = AuthorizationCenter.shared.authorizationStatus
                    await MainActor.run {
                        switch status {
                        case .approved:
                            hasScreenTimePermission = true
                            permissionStatus = "✅ Screen Time permissions granted"
                        case .denied:
                            hasScreenTimePermission = false
                            permissionStatus = "❌ Screen Time permissions denied"
                        case .notDetermined:
                            hasScreenTimePermission = false
                            permissionStatus = "⏳ Screen Time permissions not determined"
                        @unknown default:
                            hasScreenTimePermission = false
                            permissionStatus = "⚠️ Unknown permission status"
                        }
                    }
                } catch {
                    await MainActor.run {
                        hasScreenTimePermission = false
                        permissionStatus = "⚠️ Authorization failed: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            permissionStatus = "⚠️ Screen Time requires iOS 15.0+"
        }
        #else
        permissionStatus = "ℹ️ Screen Time not available in this environment"
        #endif
    }
    
    func requestScreenTimePermission() {
        #if canImport(FamilyControls)
        if #available(iOS 15.0, *) {
            _Concurrency.Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let status = AuthorizationCenter.shared.authorizationStatus
                    await MainActor.run {
                        switch status {
                        case .approved:
                            hasScreenTimePermission = true
                            permissionStatus = "✅ Screen Time permissions granted"
                        case .denied:
                            hasScreenTimePermission = false
                            permissionStatus = "❌ Screen Time permissions denied"
                            showingPermissionAlert = true
                        case .notDetermined:
                            hasScreenTimePermission = false
                            permissionStatus = "⏳ Screen Time permissions not determined"
                            showingPermissionAlert = true
                        @unknown default:
                            hasScreenTimePermission = false
                            permissionStatus = "⚠️ Unknown permission status"
                            showingPermissionAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        hasScreenTimePermission = false
                        permissionStatus = "⚠️ Authorization failed: \(error.localizedDescription)"
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            showingPermissionAlert = true
        }
        #else
        showingPermissionAlert = true
        #endif
    }
    
    func scheduleNotificationReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🍅 Focus Time Active!"
        content.body = "Distracting apps are now blocked. Stay focused on your task!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "focus-active", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - App Blocking Functions
    func applyAppRestrictions() {
        guard hasScreenTimePermission else {
            print("No Screen Time permissions to apply restrictions")
            return
        }
        
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 15.0, *) {
            // Block selected apps and categories
            store.shield.applications = selectedApps.applicationTokens
            
            // Block selected categories
            if !selectedApps.categoryTokens.isEmpty {
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selectedApps.categoryTokens)
            }
            
            if selectedApps.applicationTokens.isEmpty && selectedApps.categoryTokens.isEmpty {
                print("No apps selected to block - user should select apps first")
            }
            
            print("Applied app restrictions to \(selectedApps.applicationTokens.count) apps and \(selectedApps.categoryTokens.count) categories")
        }
        #else
        print("App blocking not available in this environment")
        #endif
    }
    
    func removeAppRestrictions() {
        guard hasScreenTimePermission else {
            print("No Screen Time permissions to remove restrictions")
            return
        }
        
        #if canImport(ManagedSettings)
        if #available(iOS 15.0, *) {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            print("Removed all app restrictions")
        }
        #else
        print("App restriction removal not available in this environment")
        #endif
    }
    
    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func showCompletionFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        showingBlockingAlert = true
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Focus Session Complete!"
        content.body = "Congratulations! You've successfully completed your 10-minute focus session. Apps are now unblocked!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "session-complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Helper Functions
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
    }
}
