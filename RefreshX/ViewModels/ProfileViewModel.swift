// ProfileViewModel.swift
import SwiftUI
import Supabase
import UserNotifications

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var bio: String = ""
    @Published var selectedWeekdays: Set<String> = []
    @Published var jobStartDate: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var jobEndDate: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    @Published var jobStart: String = "09:00"
    @Published var jobEnd: String = "17:00"
    @Published var numBreaks: Int = 5
    @Published var breakDuration: Int = 20
    @Published var todayBreakTimes: [Date] = []
    @Published var isWorkday: Bool = false
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    @Published var nextBreakTime: String = "Calculating..."
    @Published var bmi: Double? = nil
    @Published var bmiCategory: BMICalculator.BMICategory? = nil
    
    let allWeekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private var authViewModel: AuthViewModel
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private let supabaseTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        if let user = authViewModel.user {
            loadUserData(user)
            calculateBMI()
            calculateTodayBreakTimes(for: user)
            nextBreakTime = calculateAndGetNextBreakTime()
        }
    }
    
    func updateAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        if let user = authViewModel.user {
            loadUserData(user)
            calculateBMI()
            calculateTodayBreakTimes(for: user)
            nextBreakTime = calculateAndGetNextBreakTime()
        }
    }
    
    func loadUserData(_ user: User) {
        name = user.name
        height = user.height != nil ? String(format: "%.1f", user.height!) : ""
        weight = user.weight != nil ? String(format: "%.1f", user.weight!) : ""
        bio = user.bio ?? ""
        selectedWeekdays = Set(user.weekdays)
        jobStart = user.jobStart
        jobEnd = user.jobEnd
        
        var startDate: Date?
        var endDate: Date?
        
        if let date = supabaseTimeFormatter.date(from: user.jobStart) {
            startDate = date
            jobStart = timeFormatter.string(from: date)
        } else if let date = timeFormatter.date(from: user.jobStart) {
            startDate = date
        }
        
        if let date = supabaseTimeFormatter.date(from: user.jobEnd) {
            endDate = date
            jobEnd = timeFormatter.string(from: date)
        } else if let date = timeFormatter.date(from: user.jobEnd) {
            endDate = date
        }
        
        if let start = startDate {
            jobStartDate = start
        } else {
            jobStartDate = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
            jobStart = "09:00"
        }
        
        if let end = endDate {
            jobEndDate = end
        } else {
            jobEndDate = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
            jobEnd = "17:00"
        }
        
        numBreaks = user.numBreaks
        breakDuration = user.breakDuration
        nextBreakTime = calculateAndGetNextBreakTime()
    }
    
    func calculateBMI() {
        guard let heightValue = Double(height.trimmingCharacters(in: .whitespaces)),
              let weightValue = Double(weight.trimmingCharacters(in: .whitespaces)),
              heightValue > 0, weightValue > 0 else {
            bmi = nil
            bmiCategory = nil
            return
        }
        
        let calculatedBMI = BMICalculator.calculateBMI(height: heightValue, weight: weightValue)
        bmi = calculatedBMI
        bmiCategory = BMICalculator.getCategory(bmi: calculatedBMI)
    }
    
    func saveUserData() async {
        guard let userId = authViewModel.userId else {
            errorMessage = "No user ID available"
            showError = true
            isSaving = false
            return
        }
        
        isSaving = true
        jobStart = timeFormatter.string(from: jobStartDate)
        jobEnd = timeFormatter.string(from: jobEndDate)
        
        let heightDouble = Double(height.trimmingCharacters(in: .whitespaces))
        let weightDouble = Double(weight.trimmingCharacters(in: .whitespaces))
        let weekdays = Array(selectedWeekdays).sorted { allWeekdays.firstIndex(of: $0)! < allWeekdays.firstIndex(of: $1)! }
        
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
            try await authViewModel.supabase.database
                .from("users")
                .update(updatedUser)
                .eq("id", value: userId.uuidString)
                .execute()
            
            let users: [User] = try await authViewModel.supabase.database
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let fetchedUser = users.first {
                authViewModel.user = fetchedUser
                loadUserData(fetchedUser)
                calculateBMI()
                calculateTodayBreakTimes(for: fetchedUser)
                await scheduleBreakNotifications()
                nextBreakTime = calculateAndGetNextBreakTime()
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch updated user"])
            }
            
            isEditing = false
        } catch {
            errorMessage = "Failed to update profile"
            showError = true
        }
        
        isSaving = false
    }
    
    func scheduleBreakNotifications() async {
        guard let user = authViewModel.user else { return }
        await NotificationManager.shared.scheduleBreakNotifications(for: user)
    }
    
    func calculateTodayBreakTimes(for user: User) {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = weekdayNames[today - 1]
        
        isWorkday = user.weekdays.contains(todayName)
        todayBreakTimes = isWorkday ? NotificationManager.shared.calculateBreakTimes(for: user) : []
    }
    
    func calculateAndGetNextBreakTime() -> String {
        guard let user = authViewModel.user else {
            return "No user data available"
        }
        
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = weekdayNames[today - 1]
        
        if !user.weekdays.contains(todayName) {
            return "No breaks scheduled today"
        }
        
        let breakTimes = NotificationManager.shared.calculateBreakTimes(for: user)
        let now = Date()
        
        if let nextBreak = breakTimes.first(where: { $0 > now }) {
            return displayFormatter.string(from: nextBreak)
        }
        
        return "No more breaks today"
    }
    
    func formatTime(_ date: Date) -> String {
        return displayFormatter.string(from: date)
    }
}
