// ExerciseLibraryViewModel.swift
import SwiftUI
import Supabase

@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var routineExerciseIds: Set<UUID> = []
    @Published var selectedFocusArea: FocusArea? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    
    // Track if we've already tried to fetch exercises
    private var hasAttemptedExerciseFetch = false
    private var hasAttemptedRoutineFetch = false
    
    // Computed property for filtered exercises
    var filteredExercises: [Exercise] {
        if let focusArea = selectedFocusArea {
            return exercises.filter { $0.focusArea == focusArea }
        } else {
            return exercises
        }
    }
    
    // MARK: - API Functions
    
    func fetchExercises() async {
        // If we already have exercises, don't show loading indicator again
        let showLoadingIndicator = exercises.isEmpty
        if showLoadingIndicator {
            isLoading = true
        }
        
        do {
            // Fetch all exercises
            let exercises: [Exercise] = try await supabase.database
                .from("exercises")
                .select()
                .execute()
                .value
            
            self.exercises = exercises
            hasAttemptedExerciseFetch = true
            print("Fetched \(exercises.count) exercises")
        } catch {
            // Log the error
            print("Warning: Error fetching exercises - \(error.localizedDescription)")
            
            // Only show error message if this is a subsequent failure
            // and we don't already have data
            if hasAttemptedExerciseFetch && exercises.isEmpty {
                // We'll only show the error in DEBUG, not in production
                #if DEBUG
                // Keep this commented out for now to avoid showing errors
                // self.errorMessage = "Failed to load exercises"
                // self.showError = true
                #endif
            }
            hasAttemptedExerciseFetch = true
        }
        
        if showLoadingIndicator {
            isLoading = false
        }
    }
    
    func fetchRoutines() async {
        guard let userId = await getUserId() else { return }
        
        do {
            // Fetch all user routines
            let routines: [Routine] = try await supabase.database
                .from("routines")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            routineExerciseIds = Set(routines.map { $0.exerciseId })
            hasAttemptedRoutineFetch = true
            print("Fetched \(routines.count) routines")
        } catch {
            // Log the error
            print("Warning: Error fetching routines - \(error.localizedDescription)")
            
            // No need to show routine errors to the user
            // If we can't fetch routines, we just won't show any as selected
            hasAttemptedRoutineFetch = true
        }
    }
    
    func toggleRoutine(_ exercise: Exercise) async {
        guard let userId = await getUserId() else { return }
        
        if isExerciseInRoutine(exercise) {
            // Remove from routine
            do {
                try await supabase.database
                    .from("routines")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("exercise_id", value: exercise.id.uuidString)
                    .execute()
                
                routineExerciseIds.remove(exercise.id)
                print("Removed exercise from routine: \(exercise.name)")
            } catch {
                // This is a user-initiated action, so we should show an error
                showUserFacingError(error, message: "Failed to remove from routine")
            }
        } else {
            // Add to routine
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
                
                routineExerciseIds.insert(exercise.id)
                print("Added exercise to routine: \(exercise.name)")
            } catch {
                // This is a user-initiated action, so we should show an error
                showUserFacingError(error, message: "Failed to add to routine")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func isExerciseInRoutine(_ exercise: Exercise) -> Bool {
        return routineExerciseIds.contains(exercise.id)
    }
    
    private func getUserId() async -> UUID? {
        do {
            // Try to access the session properly with error handling
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            // Store userId in UserDefaults as a fallback
            UserDefaults.standard.set(userId.uuidString, forKey: "userId")
            
            print("Retrieved userId from auth session: \(userId)")
            return userId
        } catch {
            // If that fails, try to retrieve from UserDefaults as a fallback
            if let storedUserId = UserDefaults.standard.string(forKey: "userId"),
               let userId = UUID(uuidString: storedUserId) {
                print("Retrieved userId from UserDefaults: \(userId)")
                return userId
            }
            
            // Only log the error, don't show to user
            print("Error getting user ID: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func showUserFacingError(_ error: Error, message: String? = nil) {
        let errorMessage = message ?? error.localizedDescription
        print("Error: \(errorMessage) - \(error)")
        self.errorMessage = errorMessage
        self.showError = true
    }
}
