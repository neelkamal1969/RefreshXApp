// ProgressViewModel.swift
import SwiftUI
import Supabase

@MainActor
class ProgressViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Statistics
    @Published var currentStreak: Int = 0
    @Published var totalCaloriesBurned: Double = 0
    @Published var completedBreaksToday: Int = 0
    @Published var missedBreaksToday: Int = 0
    @Published var exercisesByFocusArea: [FocusArea: Int] = [:]
    @Published var dailyGoalProgress: Double = 0.0 // 0.0 to 1.0
    
    // Calendar
    @Published var selectedDate: Date = Date()
    @Published var calendarBreaks: [Date: [Break]] = [:] // Breaks grouped by day
    
    // Selected day details
    @Published var selectedDayBreaks: [Break] = []
    @Published var selectedDayExercises: [Exercise] = []
    @Published var selectedDayCalories: Double = 0
    
    // State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    // References
    var authViewModel: AuthViewModel
    private var userId: UUID? { authViewModel.userId }
    
    // Date formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Initialization
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        isLoading = true
        
        await fetchBreaksData()
        calculateStatistics()
        await loadSelectedDayData()
        
        isLoading = false
    }
    
    func fetchBreaksData() async {
        guard let userId = userId else { return }
        
        do {
            // Fetch all breaks for the user
            let breaks: [Break] = try await supabase.database
                .from("breaks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("scheduled_time", ascending: false)
                .execute()
                .value
            
            print("Fetched \(breaks.count) breaks")
            
            // Group breaks by day
            var breaksByDay: [String: [Break]] = [:]
            
            for breakItem in breaks {
                let dateKey = dateFormatter.string(from: breakItem.scheduledTime)
                if breaksByDay[dateKey] == nil {
                    breaksByDay[dateKey] = []
                }
                breaksByDay[dateKey]?.append(breakItem)
            }
            
            // Convert to dictionary with Date keys for the calendar
            calendarBreaks = breaksByDay.reduce(into: [:]) { result, entry in
                if let date = dateFormatter.date(from: entry.key) {
                    result[date] = entry.value
                }
            }
            
            // Calculate streak
            calculateStreak(breaks: breaks)
            
        } catch {
            print("Error fetching breaks data: \(error.localizedDescription)")
            errorMessage = "Failed to load progress data"
            showError = true
        }
    }
    
    func calculateStatistics() {
        calculateCompletedAndMissedBreaksToday()
        calculateDailyGoalProgress()
    }
    
    func loadSelectedDayData() async {
        // Format selected date to match the keys in our dictionary
        let dateKey = dateFormatter.string(from: selectedDate)
        if let date = dateFormatter.date(from: dateKey) {
            selectedDayBreaks = calendarBreaks[date] ?? []
        } else {
            selectedDayBreaks = []
        }
        
        // Fetch exercise details for the selected day's breaks
        await fetchExercisesForSelectedDay()
        
        // Calculate calories burned for the selected day
        calculateSelectedDayCalories()
    }
    
    private func fetchExercisesForSelectedDay() async {
        // Get unique exercise IDs from the breaks
        let exerciseIds = selectedDayBreaks.compactMap { $0.exerciseId }.map { $0.uuidString }
        
        if exerciseIds.isEmpty {
            selectedDayExercises = []
            return
        }
        
        do {
            // Fetch exercises
            let exercises: [Exercise] = try await supabase.database
                .from("exercises")
                .select()
                .in("id", values: exerciseIds)
                .execute()
                .value
            
            selectedDayExercises = exercises
            
            // Count exercises by focus area
            var countByFocusArea: [FocusArea: Int] = [:]
            for exercise in exercises {
                countByFocusArea[exercise.focusArea, default: 0] += 1
            }
            exercisesByFocusArea = countByFocusArea
            
        } catch {
            print("Error fetching exercises for selected day: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStreak(breaks: [Break]) {
        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // Group breaks by day
        let breaksByDay = Dictionary(grouping: breaks) { (breakItem: Break) -> Date in
            calendar.startOfDay(for: breakItem.scheduledTime)
        }
        
        // Count consecutive days with completed breaks
        while true {
            if let dayBreaks = breaksByDay[checkDate],
               dayBreaks.contains(where: { $0.completed }) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        self.currentStreak = currentStreak
    }
    
    private func calculateCompletedAndMissedBreaksToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todayBreaks = calendarBreaks[today] ?? []
        
        completedBreaksToday = todayBreaks.filter { $0.completed }.count
        
        // If user has a schedule, calculate missed breaks
        if let user = authViewModel.user {
            // Get expected number of breaks from user settings
            let expectedBreaks = user.numBreaks
            
            // Determine if today is a workday
            let weekday = calendar.component(.weekday, from: Date()) - 1
            let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let todayName = weekdayNames[weekday]
            
            if user.weekdays.contains(todayName) {
                // Calculate breaks that should have occurred by now
                let now = Date()
                let breakTimes = NotificationManager.shared.calculateBreakTimes(for: user)
                let pastBreaks = breakTimes.filter { $0 <= now }.count
                
                // Missed breaks are past scheduled breaks minus completed breaks
                missedBreaksToday = max(0, pastBreaks - completedBreaksToday)
            } else {
                // Not a workday, so no missed breaks
                missedBreaksToday = 0
            }
        } else {
            missedBreaksToday = 0
        }
    }
    
    private func calculateDailyGoalProgress() {
        if let user = authViewModel.user {
            let totalExpected = user.numBreaks
            if totalExpected > 0 {
                dailyGoalProgress = Double(completedBreaksToday) / Double(totalExpected)
            } else {
                dailyGoalProgress = 0
            }
        } else {
            dailyGoalProgress = 0
        }
    }
    
    private func calculateSelectedDayCalories() {
        guard let userWeight = authViewModel.user?.weight else {
            selectedDayCalories = 0
            return
        }
        
        var totalCalories: Double = 0
        
        // Loop through completed breaks with exercises
        for breakItem in selectedDayBreaks where breakItem.completed && breakItem.exerciseId != nil {
            // Find matching exercise
            if let exercise = selectedDayExercises.first(where: { $0.id == breakItem.exerciseId }) {
                // Calculate calories for this exercise
                let calories = exercise.caloriesBurned(weight: userWeight)
                totalCalories += calories
            }
        }
        
        selectedDayCalories = totalCalories
        
        // Also update total calories burned (for today if selected day is today)
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            totalCaloriesBurned = totalCalories
        }
    }
    
    // MARK: - Date Selection
    
    func selectDate(_ date: Date) {
        selectedDate = date
        
        Task {
            await loadSelectedDayData()
        }
    }
    
    // MARK: - Helper Functions
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
