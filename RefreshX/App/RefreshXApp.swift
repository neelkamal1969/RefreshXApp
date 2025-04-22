// RefreshXApp.swift
import SwiftUI
import UserNotifications

@main
struct RefreshXApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if authViewModel.isLoggedIn {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .accentColor(.blue)
            .onAppear {
                // Request notification permissions on app launch
                Task {
                    _ = await NotificationManager.shared.requestAuthorization()
                }
            }
            .task {
                // Restore session on app launch
                await restoreSession()
            }
        }
    }

    private func restoreSession() async {
        do {
            let session = try await authViewModel.supabase.auth.session
            if !session.accessToken.isEmpty {
                let userId = session.user.id
                authViewModel.userId = userId
                authViewModel.isLoggedIn = true
                let users: [User] = try await authViewModel.supabase.database
                    .from("users")
                    .select()
                    .eq("id", value: userId)
                    .execute()
                    .value
                print("Fetched users: \(users.count)")
                
                if let user = users.first {
                    authViewModel.user = user
                    print("Session restored for user ID: \(userId)")
                    
                    // Schedule notifications for today's breaks
                    Task {
                        await NotificationManager.shared.scheduleBreakNotifications(for: user)
                    }
                }
            }
        } catch {
            print("Session restore error: \(error.localizedDescription)")
        }
    }
}
