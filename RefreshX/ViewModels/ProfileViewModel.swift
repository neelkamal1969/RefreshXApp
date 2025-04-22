// ProfileViewModel.swift
import SwiftUI
import Supabase
import UserNotifications

@MainActor
class ProfileViewModel: ObservableObject {
    // User properties
    @Published var name: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var bio: String = ""
    
    // Break settings
    @Published var selectedWeekdays: Set<String> = []
    @Published var jobStartDate: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var jobEndDate: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    @Published var jobStart: String = "09:00"
    @Published var jobEnd: String = "17:00"
    @Published var numBreaks: Int = 5
    @Published var breakDuration: Int = 20
    
    // UI state
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    @Published var nextBreakTime: String = "Calculating..."
    
    // All available weekdays
    let allWeekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    // Reference to AuthViewModel
    private var authViewModel: AuthViewModel
    
    // Date formatter for UI and saving (HH:mm)
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // Date formatter for Supabase input (HH:mm:ss)
    private let supabaseTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    // Date formatter for display
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        // Load user data if available
        if let user = authViewModel.user {
            loadUserData(user)
            nextBreakTime = calculateAndGetNextBreakTime()
        }
    }
    
    // Update the AuthViewModel reference
    func updateAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        if let user = authViewModel.user {
            loadUserData(user)
            nextBreakTime = calculateAndGetNextBreakTime()
        }
    }
    
    // Load data from User model
    func loadUserData(_ user: User) {
        name = user.name
        height = user.height != nil ? String(format: "%.1f", user.height!) : ""
        weight = user.weight != nil ? String(format: "%.1f", user.weight!) : ""
        bio = user.bio ?? ""
        
        selectedWeekdays = Set(user.weekdays)
        jobStart = user.jobStart
        jobEnd = user.jobEnd
        
        // Convert string times to Date objects, handling HH:mm:ss and HH:mm
        var startDate: Date?
        var endDate: Date?
        
        // Try HH:mm:ss first (Supabase format)
        if let date = supabaseTimeFormatter.date(from: user.jobStart) {
            startDate = date
            jobStart = timeFormatter.string(from: date) // Convert to HH:mm for UI
        } else if let date = timeFormatter.date(from: user.jobStart) {
            startDate = date
        }
        
        if let date = supabaseTimeFormatter.date(from: user.jobEnd) {
            endDate = date
            jobEnd = timeFormatter.string(from: date) // Convert to HH:mm for UI
        } else if let date = timeFormatter.date(from: user.jobEnd) {
            endDate = date
        }
        
        if let start = startDate {
            jobStartDate = start
        } else {
            print("Failed to parse jobStart: \(user.jobStart)")
            jobStartDate = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
            jobStart = "09:00"
        }
        
        if let end = endDate {
            jobEndDate = end
        } else {
            print("Failed to parse jobEnd: \(user.jobEnd)")
            jobEndDate = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
            jobEnd = "17:00"
        }
        
        numBreaks = user.numBreaks
        breakDuration = user.breakDuration
        
        // Calculate next break time
        nextBreakTime = calculateAndGetNextBreakTime()
    }
    
    // Save user data
    func saveUserData() async {
        guard let userId = authViewModel.userId else {
            errorMessage = "No user ID available"
            showError = true
            isSaving = false
            return
        }
        
        isSaving = true
        
        // Convert Date objects to string times (HH:mm for consistency)
        jobStart = timeFormatter.string(from: jobStartDate)
        jobEnd = timeFormatter.string(from: jobEndDate)
        
        // Convert string values to appropriate types
        let heightDouble = Double(height.trimmingCharacters(in: .whitespaces))
        let weightDouble = Double(weight.trimmingCharacters(in: .whitespaces))
        
        // Create weekdays array from selection
        let weekdays = Array(selectedWeekdays).sorted { allWeekdays.firstIndex(of: $0)! < allWeekdays.firstIndex(of: $1)! }
        
        // Create updated user object
        let updatedUser = User(
            id: userId,
            name: name.isEmpty ? "User" : name,
            email: authViewModel.user?.email ?? "",
            height: heightDouble,
            weight: weightDouble,
            bio: bio.isEmpty ? nil : bio,
            weekdays: weekdays.isEmpty ? ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"] : weekdays,
            jobStart: jobStart,
            jobEnd: jobEnd,
            numBreaks: numBreaks,
            breakDuration: breakDuration
        )
        
        do {
            // Update user in Supabase
            try await authViewModel.supabase.database
                .from("users")
                .update(updatedUser)
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("User updated successfully with jobStart: \(updatedUser.jobStart), jobEnd: \(updatedUser.jobEnd)")
            
            // Reload user data to ensure consistency
            let users: [User] = try await authViewModel.supabase.database
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let fetchedUser = users.first {
                authViewModel.user = fetchedUser
                loadUserData(fetchedUser)
                print("Reloaded user: jobStart: \(fetchedUser.jobStart), jobEnd: \(fetchedUser.jobEnd)")
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch updated user"])
            }
            
            // Schedule notifications based on updated settings
            await scheduleBreakNotifications()
            
            // Update next break time
            nextBreakTime = calculateAndGetNextBreakTime()
            
            isEditing = false
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            showError = true
            print("Error updating user: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    // Calculate and schedule break notifications
    func scheduleBreakNotifications() async {
        guard let user = authViewModel.user else { return }
        
        // Delegate scheduling to NotificationManager
        await NotificationManager.shared.scheduleBreakNotifications(for: user)
    }
    
    // Calculate next break time and return as formatted string
    func calculateAndGetNextBreakTime() -> String {
        guard let user = authViewModel.user else {
            return "No user data available"
        }
        
        // Get today's date components
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = weekdayNames[today - 1] // Adjust for 1-based weekday in Calendar
        
        // Check if today is a work day
        if !user.weekdays.contains(todayName) {
            return "No breaks scheduled today"
        }
        
        // Use NotificationManager to calculate break times
        let breakTimes = NotificationManager.shared.calculateBreakTimes(for: user)
        let now = Date()
        
        // Debug: Log break times
        print("Calculated break times: \(breakTimes.map { displayFormatter.string(from: $0) })")
        
        // Find the next break that hasn't passed yet
        if let nextBreak = breakTimes.first(where: { $0 > now }) {
            return displayFormatter.string(from: nextBreak)
        }
        
        return "No more breaks today"
    }
}
