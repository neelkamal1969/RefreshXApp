// AuthViewModel.swift
import SwiftUI
import Supabase

struct DeleteResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
    }
}

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userId: UUID?
    @Published var errorMessage: String?
    @Published var user: User?
    @Published var isOTPMode = false
    @Published var isLoading = false
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://ilnpsjaucxmgixhxevah.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsbnBzamF1Y3htZ2l4aHhldmFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MDA5NTEsImV4cCI6MjA2MDI3Njk1MX0.7B0cIhqMTXil_2el3paP9YNgRUW5e_Ik0oRVBeMTM2E"
    )
    
    init() {
        Task {
            await checkSession()
        }
    }
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            if !session.accessToken.isEmpty {
                let userId = session.user.id
                await MainActor.run {
                    self.userId = userId
                    self.isLoggedIn = true
                }
                await loadUserData(userId: userId)
            }
        } catch {
            print("Session check error: \(error.localizedDescription)")
        }
    }
    
    func loadUserData(userId: UUID) async {
        do {
            let users: [User] = try await supabase.database
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            await MainActor.run {
                self.user = users.first
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load user data"
            }
            print("User data load error: \(error.localizedDescription)")
        }
    }
    
    func sendOTP(email: String) async {
        guard email.contains("@") && email.contains(".") else {
            await MainActor.run {
                self.errorMessage = "Please enter a valid email"
                self.isLoading = false
            }
            return
        }
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            try await supabase.auth.signInWithOTP(email: email)
            await MainActor.run {
                self.isOTPMode = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to send OTP"
                self.isLoading = false
            }
            print("Send OTP error: \(error.localizedDescription)")
        }
    }
    
    func verifyOTP(email: String, token: String) async {
        guard !token.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Please enter the OTP"
                self.isLoading = false
            }
            return
        }
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            let response = try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            let userId = response.user.id
            await checkSession() // Refresh session
            let session = try await supabase.auth.session
            print("Session after verify: \(session.user.id.uuidString), isActive: \(!session.accessToken.isEmpty)")
            
            let users: [User] = try await supabase.database
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if users.isEmpty {
                let newUser = User(
                    id: userId,
                    email: email
                )
                try await supabase.database
                    .from("users")
                    .insert(newUser)
                    .execute()
                print("User inserted: \(userId.uuidString)")
                
                // Fetch all exercises first
                let allExercises: [Exercise] = try await supabase.database
                    .from("exercises")
                    .select()
                    .execute()
                    .value
                print("All exercises fetched: \(allExercises.map { $0.name ?? "nil" })")
                
                // Filter default exercises client-side
                let defaultExerciseNames = ["20-20-20 Rule", "Seated Twist", "Wrist Flexor"]
                let defaultExercises = allExercises.filter { defaultExerciseNames.contains($0.name ?? "") }
                print("Filtered default exercises: \(defaultExercises.map { $0.name ?? "nil" })")
                
                // Add default exercises to routines
                for exercise in defaultExercises {
                    let routine = Routine(
                        id: UUID(),
                        userId: userId,
                        exerciseId: exercise.id
                    )
                    do {
                        try await supabase.database
                            .from("routines")
                            .insert(routine)
                            .execute()
                        print("Routine inserted for exercise: \(exercise.name ?? "nil"), user: \(userId.uuidString)")
                    } catch {
                        print("Failed to insert routine for \(exercise.name ?? "nil"): \(error.localizedDescription)")
                    }
                }
                
                await MainActor.run {
                    self.user = newUser
                }
            } else {
                await MainActor.run {
                    self.user = users.first
                }
            }
            
            await MainActor.run {
                self.isLoggedIn = true
                self.userId = userId
                self.isOTPMode = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Invalid OTP, try again"
                self.isLoading = false
            }
            print("Verify OTP error: \(error.localizedDescription)")
        }
    }
    
    func signOut() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                self.isLoggedIn = false
                self.userId = nil
                self.user = nil
                self.isOTPMode = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to sign out"
                self.isLoading = false
            }
            print("Sign out error: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async {
        guard let userId = userId else {
            await MainActor.run {
                self.errorMessage = "No user to delete"
                self.isLoading = false
            }
            return
        }
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            let response: DeleteResponse = try await supabase.functions
                .invoke(
                    "delete-user",
                    options: FunctionInvokeOptions(
                        body: ["user_id": userId.uuidString]
                    )
                )
            if !response.success {
                throw NSError(
                    domain: "",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: response.error ?? "Deletion failed"]
                )
            }
            try await supabase.auth.signOut()
            await MainActor.run {
                self.isLoggedIn = false
                self.userId = nil
                self.user = nil
                self.isOTPMode = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete account"
                self.isLoading = false
            }
            print("Delete account error: \(error.localizedDescription)")
        }
    }
}
