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
    
    // Cache timestamps
    private var lastExerciseFetchTime: Date? = nil
    private var lastRoutineFetchTime: Date? = nil
    
    // Cache timeout in seconds (15 minutes)
    private let cacheTimeout: TimeInterval = 900
    
    init() {
        // Clean up old large cache on initialization
        cleanupLegacyCache()
    }
    
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
        // Check cache first
        if !exercises.isEmpty,
           let lastFetch = lastExerciseFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            print("Using cached exercise data")
            return
        }
        
        // If we already have exercises, don't show loading indicator again
        let showLoadingIndicator = exercises.isEmpty
        if showLoadingIndicator {
            isLoading = true
        }
        
        do {
            print("Fetching exercises from Supabase...")
            
            // Fetch all exercises with a single query
            let exercises: [Exercise] = try await supabase.database
                .from("exercises")
                .select()
                .execute()
                .value
            
            self.exercises = exercises
            lastExerciseFetchTime = Date()
            hasAttemptedExerciseFetch = true
            print("Successfully fetched \(exercises.count) exercises")
            
            // Cache exercises using FileManager
            await saveExercisesToFileCache(exercises)
        } catch {
            print("Warning: Error fetching exercises - \(error.localizedDescription)")
            
            // Try to load from cache
            if let cachedExercises = await loadExercisesFromFileCache() {
                self.exercises = cachedExercises
                print("Loaded \(cachedExercises.count) exercises from cache")
            } else if hasAttemptedExerciseFetch && exercises.isEmpty {
                self.errorMessage = "Failed to load exercises. Please check your connection and try again."
                self.showError = true
            }
            
            hasAttemptedExerciseFetch = true
        }
        
        if showLoadingIndicator {
            isLoading = false
        }
    }
    
    func fetchRoutines() async {
        // Check cache first
        if !routineExerciseIds.isEmpty,
           let lastFetch = lastRoutineFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            print("Using cached routine data")
            return
        }
        
        guard let userId = await getUserId() else {
            print("Cannot fetch routines - user ID not available")
            return
        }
        
        do {
            print("Fetching routines from Supabase...")
            
            // Fetch all user routines
            let routines: [Routine] = try await supabase.database
                .from("routines")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            routineExerciseIds = Set(routines.map { $0.exerciseId })
            lastRoutineFetchTime = Date()
            hasAttemptedRoutineFetch = true
            print("Successfully fetched \(routines.count) routines")
            
            // Cache routine IDs
            saveRoutinesToCache(Array(routineExerciseIds))
        } catch {
            print("Warning: Error fetching routines - \(error.localizedDescription)")
            
            // Try to load from cache
            if let cachedRoutines = loadRoutinesFromCache() {
                self.routineExerciseIds = Set(cachedRoutines)
                print("Loaded \(cachedRoutines.count) routines from cache")
            }
            
            hasAttemptedRoutineFetch = true
        }
    }
    
    func toggleRoutine(_ exercise: Exercise) async {
        guard let userId = await getUserId() else {
            showUserFacingError(NSError(domain: "RefreshX", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve user ID"]), message: "Please log in again")
            return
        }
        
        if isExerciseInRoutine(exercise) {
            // Remove from routine
            do {
                print("Removing exercise from routine: \(exercise.name)")
                
                try await supabase.database
                    .from("routines")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("exercise_id", value: exercise.id.uuidString)
                    .execute()
                
                routineExerciseIds.remove(exercise.id)
                lastRoutineFetchTime = Date()
                
                // Update cache
                saveRoutinesToCache(Array(routineExerciseIds))
                
                print("Successfully removed exercise from routine")
            } catch {
                // This is a user-initiated action, so we should show an error
                showUserFacingError(error, message: "Failed to remove from routine")
            }
        } else {
            // Add to routine
            do {
                print("Adding exercise to routine: \(exercise.name)")
                
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
                lastRoutineFetchTime = Date()
                
                // Update cache
                saveRoutinesToCache(Array(routineExerciseIds))
                
                print("Successfully added exercise to routine")
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
    
    // MARK: - New FileManager Caching Functions
    
    private func cleanupLegacyCache() {
        // Remove the problematic old large caches
        UserDefaults.standard.removeObject(forKey: "cachedExercises")
        print("Cleaned up legacy exercise cache")
    }
    
    private func getDocumentsDirectory() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
    }
    
    private func saveExercisesToFileCache(_ exercises: [Exercise]) async {
        do {
            // Create lightweight version of exercises for caching
            let cacheData = exercises.map { exercise -> [String: Any] in
                return [
                    "id": exercise.id.uuidString,
                    "name": exercise.name,
                    "focusArea": exercise.focusArea.rawValue,
                    "duration": exercise.duration,
                    "repetitions": exercise.repetitions,
                    "metScore": exercise.metScore,
                    // Store a truncated version of instructions to save space
                    "instructions": String(exercise.instructions.prefix(150))
                ]
            }
            
            let data = try JSONSerialization.data(withJSONObject: cacheData)
            
            // Get documents directory
            let fileURL = try getDocumentsDirectory().appendingPathComponent("cached_exercises.json")
            
            // Write to file
            try data.write(to: fileURL)
            
            // Record timestamp in UserDefaults (tiny amount of data)
            UserDefaults.standard.set(Date(), forKey: "exercisesCacheTimestamp")
            
            print("Saved \(exercises.count) exercises to file cache")
        } catch {
            print("Failed to save exercises to file cache: \(error.localizedDescription)")
        }
    }
    
    private func loadExercisesFromFileCache() async -> [Exercise]? {
        do {
            // Get file URL
            let fileURL = try getDocumentsDirectory().appendingPathComponent("cached_exercises.json")
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("No cached exercise file found")
                return nil
            }
            
            // Load data
            let data = try Data(contentsOf: fileURL)
            
            // Parse data
            guard let cacheData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("Invalid cache format")
                return nil
            }
            
            // Convert to Exercise objects
            let exercises = cacheData.compactMap { dict -> Exercise? in
                guard
                    let idString = dict["id"] as? String,
                    let id = UUID(uuidString: idString),
                    let name = dict["name"] as? String,
                    let focusAreaRaw = dict["focusArea"] as? String,
                    let focusArea = FocusArea(rawValue: focusAreaRaw),
                    let duration = dict["duration"] as? Int,
                    let repetitions = dict["repetitions"] as? Int,
                    let metScore = dict["metScore"] as? Double,
                    let instructions = dict["instructions"] as? String
                else {
                    return nil
                }
                
                // Create a minimal exercise without the thumbnail
                return Exercise(
                    id: id,
                    name: name,
                    instructions: instructions,
                    thumbnailBase64: nil,
                    duration: duration,
                    repetitions: repetitions,
                    focusArea: focusArea,
                    metScore: metScore
                )
            }
            
            print("Loaded \(exercises.count) exercises from file cache")
            return exercises
        } catch {
            print("Failed to load exercises from file cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - UserDefaults for small data (routines)
    
    private func saveRoutinesToCache(_ routineIds: [UUID]) {
        do {
            let routineStrings = routineIds.map { $0.uuidString }
            let data = try JSONEncoder().encode(routineStrings)
            UserDefaults.standard.set(data, forKey: "cachedRoutines")
            print("Saved \(routineIds.count) routines to cache")
        } catch {
            print("Failed to save routines to cache: \(error.localizedDescription)")
        }
    }
    
    private func loadRoutinesFromCache() -> [UUID]? {
        guard let data = UserDefaults.standard.data(forKey: "cachedRoutines") else {
            print("No cached routines found")
            return nil
        }
        
        do {
            let routineStrings = try JSONDecoder().decode([String].self, from: data)
            let routineIds = routineStrings.compactMap { UUID(uuidString: $0) }
            print("Loaded \(routineIds.count) routines from cache")
            return routineIds
        } catch {
            print("Failed to decode cached routines: \(error.localizedDescription)")
            return nil
        }
    }
}
