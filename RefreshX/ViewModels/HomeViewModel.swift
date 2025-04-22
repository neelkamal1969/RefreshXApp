// HomeViewModel.swift
import SwiftUI
import Supabase

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Break timer state
    @Published var isBreakActive = false
    @Published var remainingBreakTime: Int = 0
    @Published var selectedExerciseIndex: Int = 0
    
    // Routine exercises
    @Published var routineExercises: [Exercise] = []
    @Published var isLoadingRoutine = false
    @Published var showExercisePicker = false
    @Published var availableExercises: [Exercise] = []
    
    // Current break tracking
    @Published var currentBreak: Break?
    @Published var nextBreakTime: String = "No scheduled breaks"
    
    // UI state
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Timer
    private var timer: Timer?
    private var exerciseTimer: Timer?
    
    // References
    var authViewModel: AuthViewModel
    private var userId: UUID? { authViewModel.userId }
    
    // MARK: - Initialization
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        // Set default break duration from user settings
        if let breakDuration = authViewModel.user?.breakDuration {
            self.remainingBreakTime = breakDuration * 60 // Convert minutes to seconds
        }
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        await fetchRoutineExercises()
        await updateNextBreakTime()
    }
    
    func fetchRoutineExercises() async {
        guard let userId = userId else { return }
        
        isLoadingRoutine = true
        
        do {
            // Get user's routine exercise IDs
            let routines: [Routine] = try await supabase.database
                .from("routines")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            // No routines, empty result
            if routines.isEmpty {
                routineExercises = []
                isLoadingRoutine = false
                return
            }
            
            // Get exercise details for each routine
            let exerciseIds = routines.map { $0.exerciseId.uuidString }
            
            let exercises: [Exercise] = try await supabase.database
                .from("exercises")
                .select()
                .in("id", values: exerciseIds)
                .execute()
                .value
            
            // Map exercises to the order in routines
            let exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
            let orderedExercises = routines.compactMap { exerciseMap[$0.exerciseId] }
            
            routineExercises = orderedExercises
            print("Fetched \(routineExercises.count) routine exercises")
        } catch {
            print("Error fetching routine exercises: \(error.localizedDescription)")
            errorMessage = "Failed to load your exercise routine"
            showError = true
        }
        
        isLoadingRoutine = false
    }
    
    func fetchAvailableExercises() async {
        guard let userId = userId else { return }
        
        do {
            // Get all exercises
            let allExercises: [Exercise] = try await supabase.database
                .from("exercises")
                .select()
                .execute()
                .value
            
            // Get user's routine exercise IDs
            let routines: [Routine] = try await supabase.database
                .from("routines")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            let routineExerciseIds = Set(routines.map { $0.exerciseId })
            
            // Filter out exercises already in routine
            availableExercises = allExercises.filter { !routineExerciseIds.contains($0.id) }
            print("Fetched \(availableExercises.count) available exercises")
        } catch {
            print("Error fetching available exercises: \(error.localizedDescription)")
            errorMessage = "Failed to load available exercises"
            showError = true
        }
    }
    
    // MARK: - Break Management
    
    func startBreak() async {
        // Reset state
        isBreakActive = true
        selectedExerciseIndex = 0
        
        // Set initial timer value from user settings
        if let breakDuration = authViewModel.user?.breakDuration {
            remainingBreakTime = breakDuration * 60 // Convert minutes to seconds
        } else {
            remainingBreakTime = 20 * 60 // Default: 20 minutes
        }
        
        // Create a new break record in Supabase
        await createBreakRecord()
        
        // Start the timer
        startTimer()
    }
    
    func endBreak() async {
        // Stop timers
        stopTimer()
        
        // Update break record in Supabase as completed
        await updateBreakRecord(completed: true)
        
        // Reset state
        isBreakActive = false
        selectedExerciseIndex = 0
        
        // Reset break time for next use
        if let breakDuration = authViewModel.user?.breakDuration {
            remainingBreakTime = breakDuration * 60 // Convert minutes to seconds
        }
    }
    
    private func startTimer() {
        // Cancel any existing timer
        stopTimer()
        
        // Create new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingBreakTime > 0 {
                self.remainingBreakTime -= 1
            } else {
                // Break time is up
                Task {
                    await self.endBreak()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Exercise Navigation
    
    func moveToNextExercise() {
        if selectedExerciseIndex < routineExercises.count - 1 {
            selectedExerciseIndex += 1
        } else {
            // Reached the end of routine
            Task {
                await endBreak()
            }
        }
    }
    
    func moveToPreviousExercise() {
        if selectedExerciseIndex > 0 {
            selectedExerciseIndex -= 1
        }
    }
    struct BreakUpdate: Encodable {
        let exercise_id: String
        let completed: Bool
    }

    func markExerciseComplete() async {
        if let currentBreak = currentBreak,
           let exerciseId = routineExercises[safe: selectedExerciseIndex]?.id {
            
            do {
                let updateData = BreakUpdate(
                    exercise_id: exerciseId.uuidString,
                    completed: true
                )
                
                try await supabase.database
                    .from("breaks")
                    .update(updateData)
                    .eq("id", value: currentBreak.id.uuidString)
                    .execute()
                
                print("Marked exercise as complete")
            } catch {
                print("Error marking exercise as complete: \(error.localizedDescription)")
            }
        }
        
        moveToNextExercise()
    }
    
    // MARK: - Routine Management
    
    func addExerciseToRoutine(_ exercise: Exercise) async {
        guard let userId = userId else { return }
        
        do {
            let routine = Routine(
                id: UUID(),
                userId: userId,
                exerciseId: exercise.id
            )
            
            try await supabase.database
                .from("routines")
                .insert(routine)
                .execute()
            
            print("Added exercise to routine: \(exercise.name)")
            
            // Refresh routine exercises
            await fetchRoutineExercises()
            
            // Remove from available exercises
            availableExercises.removeAll(where: { $0.id == exercise.id })
        } catch {
            print("Error adding exercise to routine: \(error.localizedDescription)")
            errorMessage = "Failed to add exercise to routine"
            showError = true
        }
    }
    
    func removeExerciseFromRoutine(at indexSet: IndexSet) async {
        guard let userId = userId else { return }
        
        // Get the exercises to remove
        let exercisesToRemove = indexSet.compactMap { routineExercises[safe: $0] }
        
        for exercise in exercisesToRemove {
            do {
                try await supabase.database
                    .from("routines")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("exercise_id", value: exercise.id.uuidString)
                    .execute()
                
                print("Removed exercise from routine: \(exercise.name)")
            } catch {
                print("Error removing exercise from routine: \(error.localizedDescription)")
                errorMessage = "Failed to remove exercise from routine"
                showError = true
            }
        }
        
        // Refresh routine exercises
        await fetchRoutineExercises()
    }
    
    // MARK: - Supabase Break Records
    
    private func createBreakRecord() async {
        guard let userId = userId else { return }
        
        do {
            let newBreak = Break(
                id: UUID(),
                userId: userId,
                scheduledTime: Date(),
                completed: false
            )
            
            try await supabase.database
                .from("breaks")
                .insert(newBreak)
                .execute()
            
            currentBreak = newBreak
            print("Created break record: \(newBreak.id)")
        } catch {
            print("Error creating break record: \(error.localizedDescription)")
        }
    }
    
    private func updateBreakRecord(completed: Bool) async {
        guard let currentBreak = currentBreak else { return }
        
        do {
            // Create a dictionary with values to update
            let updateData: [String: Bool] = ["completed": completed]
            
            try await supabase.database
                .from("breaks")
                .update(updateData)
                .eq("id", value: currentBreak.id.uuidString)
                .execute()
            
            print("Updated break record: \(currentBreak.id), completed: \(completed)")
        } catch {
            print("Error updating break record: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Next Break Time Handling
    
    func updateNextBreakTime() async {
        guard let user = authViewModel.user else {
            nextBreakTime = "No user data"
            return
        }
        
        // Use the existing NotificationManager to calculate break times
        let breakTimes = NotificationManager.shared.calculateBreakTimes(for: user)
        let now = Date()
        
        // Find the next break that hasn't passed yet
        if let nextBreak = breakTimes.first(where: { $0 > now }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            nextBreakTime = "Next break at \(formatter.string(from: nextBreak))"
        } else {
            nextBreakTime = "No more breaks today"
        }
    }
    
    // MARK: - Time Formatting
    
    func formattedTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


