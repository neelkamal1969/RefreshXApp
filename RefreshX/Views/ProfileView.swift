// ProfileView.swift
import SwiftUI
import SafariServices

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingPrivacyPolicy = false
    @State private var showingSupport = false
    @State private var showingAboutApp = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        NavigationView {
            profileContent
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
                .onAppear(perform: handleOnAppear)
                .onChange(of: authViewModel.user, perform: handleUserChange)
                .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                    deleteAccountAlertActions
                } message: {
                    Text("This will permanently delete ALL your data including your profile, routines, breaks, favorites, and reading history. This action cannot be undone.")
                }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "An unknown error occurred")
                }
                .overlay(loadingOverlay)
                .background(navigationLinks)
        }
    }
    
    // MARK: - Subviews
    
    private var profileContent: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                if let user = authViewModel.user {
                    ScrollView {
                        VStack(spacing: 16) {
                            profileCard(user)
                            if viewModel.bmi != nil {
                                bmiCard
                            }
                            if !viewModel.todayBreakTimes.isEmpty {
                                todayBreaksCard
                            }
                            aboutCard(user)
                            measurementsCard(user)
                            breakScheduleCard()
                            appInfoCard
                            accountActionsCard
                            if viewModel.isEditing {
                                saveAndCancelButtons
                                    .padding(.horizontal)
                            }
                            Spacer().frame(height: 30)
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        refreshUserData()
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    private func profileCard(_ user: User) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                profileImage
                profileInfo(user)
                Spacer()
            }
            if !viewModel.isEditing {
                nextBreakView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var profileImage: some View {
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
    }
    
    private func profileInfo(_ user: User) -> some View {
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
    }
    
    private var nextBreakView: some View {
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
    
    private var bmiCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                Text("BMI")
                    .font(.headline)
                Spacer()
            }
            
            if let bmi = viewModel.bmi, let category = viewModel.bmiCategory {
                bmiContentView(bmi: bmi, category: category)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    private func bmiContentView(bmi: Double, category: BMICalculator.BMICategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(String(format: "%.1f", bmi))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Spacer()
                Text(category.rawValue)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(category.color.opacity(0.2))  // Using the category's color
                    .foregroundColor(category.color)           // Using the category's color
                    .cornerRadius(20)
            }
            bmiScaleView(bmi: bmi)
        }
    }
    
    private func bmiScaleView(bmi: Double) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 8)
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                )
                .offset(x: min(max(CGFloat((bmi - 15) / 25) * 200 - 8, 0), 192))
        }
    }
    
    private var todayBreaksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                Text("Today's Breaks")
                    .font(.headline)
                Spacer()
            }
            
            if viewModel.isWorkday {
                breaksListView
            } else {
                noBreaksView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var breaksListView: some View {
        ForEach(viewModel.todayBreakTimes.indices, id: \.self) { index in
            let breakTime = viewModel.todayBreakTimes[index]
            let isPast = breakTime < Date()
            
            VStack {
                HStack {
                    Text("Break \(index + 1)")
                        .fontWeight(.medium)
                    Spacer()
                    Text(viewModel.formatTime(breakTime))
                        .foregroundColor(isPast ? .secondary : .blue)
                    if isPast {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                if index < viewModel.todayBreakTimes.count - 1 {
                    Divider()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var noBreaksView: some View {
        Text("No breaks scheduled for today")
            .foregroundColor(.secondary)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
    }
    
    private func aboutCard(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.alignleft")
                    .frame(width: 24, height: 24)
                Text("About")
                    .font(.headline)
            }
            
            if viewModel.isEditing {
                bioEditor
            } else if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .foregroundColor(.primary)
            } else {
                noBioView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var bioEditor: some View {
        TextEditor(text: $viewModel.bio)
            .frame(minHeight: 100)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    private var noBioView: some View {
        Text("No bio added")
            .foregroundColor(.secondary)
            .italic()
    }
    
    private func measurementsCard(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            measurementsHeader
            
            heightRow(user)
            
            Divider()
            
            weightRow(user)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var measurementsHeader: some View {
        HStack {
            Image(systemName: "ruler")
                .frame(width: 24, height: 24)
            Text("Measurements")
                .font(.headline)
            Spacer()
            InfoButton(
                title: "Measurements",
                message: "Height and weight are used to calculate calories burned during exercises for personalized tracking."
            )
        }
    }
    
    private func heightRow(_ user: User) -> some View {
        HStack {
            Text("Height")
                .foregroundColor(.primary)
            Spacer()
            if viewModel.isEditing {
                heightTextField
            } else if let height = user.height {
                Text("\(String(format: "%.1f", height)) cm")
                    .foregroundColor(.primary)
            } else {
                Text("Not set")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private var heightTextField: some View {
        TextField("Height (cm)", text: $viewModel.height)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 100)
    }
    
    private func weightRow(_ user: User) -> some View {
        HStack {
            Text("Weight")
                .foregroundColor(.primary)
            Spacer()
            if viewModel.isEditing {
                weightTextField
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
    
    private var weightTextField: some View {
        TextField("Weight (kg)", text: $viewModel.weight)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 100)
    }
    
    private func breakScheduleCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            breakScheduleHeader
            
            workingDaysSection
            
            Divider()
            
            workHoursSection
            
            Divider()
            
            breakSettingsSection
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var breakScheduleHeader: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .frame(width: 24, height: 24)
            Text("Break Schedule")
                .font(.headline)
            Spacer()
            InfoButton(
                title: "Break Scheduling",
                message: "Breaks are scheduled evenly during your work hours to promote wellness. You're free to take breaks anytime; these are recommended times for optimal health."
            )
        }
    }
    
    private var workingDaysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Working Days")
                .fontWeight(.medium)
            
            if viewModel.isEditing {
                workingDaysEditor
            } else {
                Text(viewModel.selectedWeekdays.joined(separator: ", "))
            }
        }
    }
    
    private var workingDaysEditor: some View {
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
    }
    
    private var workHoursSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Work Hours")
                .fontWeight(.medium)
            
            if viewModel.isEditing {
                workHoursEditor
            } else {
                Text("From \(formatTime(viewModel.jobStart)) to \(formatTime(viewModel.jobEnd))")
            }
        }
    }
    
    private var workHoursEditor: some View {
        Group {
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
        }
    }
    
    private var breakSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Break Settings")
                .fontWeight(.medium)
            
            if viewModel.isEditing {
                breakSettingsEditor
            } else {
                Text("\(viewModel.numBreaks) breaks of \(viewModel.breakDuration) minutes")
            }
        }
    }
    
    private var breakSettingsEditor: some View {
        Group {
            HStack {
                Text("Number of breaks")
                Spacer()
                Stepper("\(viewModel.numBreaks)", value: $viewModel.numBreaks, in: 1...15, step: 1)
                    .frame(width: 120)
            }
            HStack {
                Text("Break duration (minutes)")
                Spacer()
                Stepper("\(viewModel.breakDuration)", value: $viewModel.breakDuration, in: 5...60, step: 5)
                    .frame(width: 120)
            }
        }
    }
    
    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            aboutAppButton
            
            Divider()
                .padding(.leading, 40)
            
            privacyPolicyButton
            
            Divider()
                .padding(.leading, 40)
            
            supportButton
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var aboutAppButton: some View {
        Button(action: {
            showingAboutApp = true
        }) {
            HStack {
                Image(systemName: "app.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                Text("About RefreshX")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
    
    private var privacyPolicyButton: some View {
        Button(action: {
            showingPrivacyPolicy = true
        }) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                Text("Privacy Policy")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
    
    private var supportButton: some View {
        Button(action: {
            showingSupport = true
        }) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                Text("Support")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
    }
    
    private var accountActionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            signOutButton
            
            Divider()
                .padding(.leading, 40)
            
            deleteAccountButton
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var signOutButton: some View {
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
    }
    
    private var deleteAccountButton: some View {
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
    
    private var saveAndCancelButtons: some View {
        HStack(spacing: 16) {
            cancelButton
            saveButton
        }
    }
    
    private var cancelButton: some View {
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
    }
    
    private var saveButton: some View {
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
    
    private var loadingOverlay: some View {
        Group {
            if authViewModel.isLoading || viewModel.isSaving {
                Color(.systemBackground).opacity(0.7)
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
    
    private var navigationLinks: some View {
        Group {
            NavigationLink(destination: PrivacyPolicyView(), isActive: $showingPrivacyPolicy) {
                EmptyView()
            }
            NavigationLink(destination: SupportView(), isActive: $showingSupport) {
                EmptyView()
            }
            NavigationLink(destination: AboutAppView(), isActive: $showingAboutApp) {
                EmptyView()
            }
        }
    }
    
    private var deleteAccountAlertActions: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Delete All My Data", role: .destructive) {
                Task {
                    await authViewModel.deleteAccount()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleOnAppear() {
        viewModel.updateAuthViewModel(authViewModel)
        if let user = authViewModel.user {
            viewModel.loadUserData(user)
            viewModel.calculateBMI()
            Task {
                viewModel.calculateTodayBreakTimes(for: user)
                viewModel.nextBreakTime = viewModel.calculateAndGetNextBreakTime()
            }
        }
    }
    
    private func handleUserChange(_ newUser: User?) {
        if let user = newUser {
            viewModel.loadUserData(user)
            viewModel.calculateBMI()
            viewModel.calculateTodayBreakTimes(for: user)
        }
    }
    
    private func refreshUserData() {
        if let user = authViewModel.user {
            viewModel.loadUserData(user)
            viewModel.calculateBMI()
            viewModel.calculateTodayBreakTimes(for: user)
        }
    }
    
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
