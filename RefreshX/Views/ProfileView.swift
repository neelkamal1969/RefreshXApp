
// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingDeleteConfirmation = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    if let user = authViewModel.user {
                        ScrollView {
                            VStack(spacing: 16) {
                                // User profile card
                                profileCard(user)
                                
                                // About section
                                aboutCard(user)
                                
                                // Measurements
                                measurementsCard(user)
                                
                                // Break schedule
                                breakScheduleCard()
                                
                                // Account actions
                                accountActionsCard()
                                
                                // Save/Cancel buttons when editing
                                if viewModel.isEditing {
                                    saveAndCancelButtons
                                        .padding(.horizontal)
                                }
                                
                                // Add some space at the bottom
                                Spacer().frame(height: 30)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.isEditing {
                        Button("Edit") {
                            viewModel.isEditing = true
                        }
                    }
                }
            }
            .onAppear {
                viewModel.updateAuthViewModel(authViewModel)
                if let user = authViewModel.user {
                    viewModel.loadUserData(user)
                    Task {
                        await viewModel.scheduleBreakNotifications()
                        viewModel.nextBreakTime = viewModel.calculateAndGetNextBreakTime()
                    }
                }
            }
            .onChange(of: authViewModel.user) { newUser in
                if let user = newUser {
                    viewModel.loadUserData(user)
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All My Data", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete ALL your data including your profile, routines, breaks, favorites, and reading history. This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .overlay {
                if authViewModel.isLoading || viewModel.isSaving {
                    Color(.systemBackground).opacity(0.7)
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    // MARK: - Profile Card
    
    private func profileCard(_ user: User) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                }
                
                // Name and email
                VStack(alignment: .leading, spacing: 6) {
                    if viewModel.isEditing {
                        TextField("Name", text: $viewModel.name)
                            .font(.title2.bold())
                    } else {
                        Text(user.name)
                            .font(.title2.bold())
                    }
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Next break indicator
            if !viewModel.isEditing {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                    
                    Text("Next break:")
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.nextBreakTime)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - About Card
    
    private func aboutCard(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "text.alignleft")
                    .frame(width: 24, height: 24)
                Text("About")
                    .font(.headline)
            }
            
            // Content
            if viewModel.isEditing {
                TextEditor(text: $viewModel.bio)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .foregroundColor(.primary)
            } else {
                Text("No bio added")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Measurements Card
    
    private func measurementsCard(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "ruler")
                    .frame(width: 24, height: 24)
                Text("Measurements")
                    .font(.headline)
            }
            
            // Height
            HStack {
                Text("Height")
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.isEditing {
                    TextField("Height (cm)", text: $viewModel.height)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                } else if let height = user.height {
                    Text("\(String(format: "%.1f", height)) cm")
                        .foregroundColor(.primary)
                } else {
                    Text("Not set")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Divider()
            
            // Weight
            HStack {
                Text("Weight")
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.isEditing {
                    TextField("Weight (kg)", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                } else if let weight = user.weight {
                    Text("\(String(format: "%.1f", weight)) kg")
                        .foregroundColor(.primary)
                } else {
                    Text("Not set")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Break Schedule Card
    
    private func breakScheduleCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .frame(width: 24, height: 24)
                Text("Break Schedule")
                    .font(.headline)
            }
            
            // Working days
            VStack(alignment: .leading, spacing: 8) {
                Text("Working Days")
                    .fontWeight(.medium)
                
                if viewModel.isEditing {
                    ForEach(viewModel.allWeekdays, id: \.self) { day in
                        Toggle(day, isOn: Binding(
                            get: { viewModel.selectedWeekdays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedWeekdays.insert(day)
                                } else {
                                    viewModel.selectedWeekdays.remove(day)
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                } else {
                    Text(viewModel.selectedWeekdays.joined(separator: ", "))
                }
            }
            
            Divider()
            
            // Work hours
            VStack(alignment: .leading, spacing: 8) {
                Text("Work Hours")
                    .fontWeight(.medium)
                
                if viewModel.isEditing {
                    HStack {
                        Text("Start:")
                        Spacer()
                        DatePicker("", selection: $viewModel.jobStartDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("End:")
                        Spacer()
                        DatePicker("", selection: $viewModel.jobEndDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                } else {
                    Text("From \(formatTime(viewModel.jobStart)) to \(formatTime(viewModel.jobEnd))")
                }
            }
            
            Divider()
            
            // Break settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Break Settings")
                    .fontWeight(.medium)
                
                if viewModel.isEditing {
                    HStack {
                        Text("Number of breaks")
                        Spacer()
                        Stepper("\(viewModel.numBreaks)", value: $viewModel.numBreaks, in: 1...10)
                            .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Break duration (minutes)")
                        Spacer()
                        Stepper("\(viewModel.breakDuration)", value: $viewModel.breakDuration, in: 5...60, step: 5)
                            .frame(width: 120)
                    }
                } else {
                    Text("\(viewModel.numBreaks) breaks of \(viewModel.breakDuration) minutes")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Account Actions
    
    private func accountActionsCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                Task {
                    await authViewModel.signOut()
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    Text("Sign Out")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            
            Divider()
                .padding(.leading, 40)
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                    Text("Delete Account")
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Views
    
    private var saveAndCancelButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.isEditing = false
                if let user = authViewModel.user {
                    viewModel.loadUserData(user)
                }
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            
            Button(action: {
                Task {
                    await viewModel.saveUserData()
                }
            }) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return timeString
    }
}
