// UserProgressView.swift
import SwiftUI

struct UserProgressView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProgressViewModel
    
    init() {
        // Initialize with a temporary AuthViewModel
        // The real one will be injected via environmentObject
        _viewModel = StateObject(wrappedValue: ProgressViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Summary Card
                    progressSummaryCard
                    
                    // Calendar View
                    calendarSection
                    
                    // Selected Day Details
                    selectedDayDetailsSection
                }
                .padding()
                .navigationTitle("Progress")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .onAppear {
            // Update the viewModel with the current authViewModel
            viewModel.updateAuthViewModel(authViewModel)
            
            // Load data on appearance
            Task {
                await viewModel.loadData()
            }
        }
        .onChange(of: authViewModel.user) { _ in
            // Reload data if user changes
            Task {
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color(.systemBackground).opacity(0.7)
                    ProgressView()
                        .scaleEffect(1.5)
                }
                .ignoresSafeArea()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Progress Summary Card
    
    private var progressSummaryCard: some View {
        VStack(spacing: 15) {
            // Current streak
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Streak")
                        .font(.headline)
                    Text("\(viewModel.currentStreak) days")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 5)
            
            Divider()
            
            // Today's stats
            HStack {
                // Completed breaks
                VStack {
                    Text("\(viewModel.completedBreaksToday)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Missed breaks
                VStack {
                    Text("\(viewModel.missedBreaksToday)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Missed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Calories burned
                VStack {
                    Text("\(Int(viewModel.totalCaloriesBurned))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 5)
            
            Divider()
            
            // Daily goal progress
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Daily Goal")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(min(Int(viewModel.dailyGoalProgress * 100), 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 10)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                            .cornerRadius(5)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(viewModel.dailyGoalProgress) * geometry.size.width, geometry.size.width), height: 10)
                            .foregroundColor(.blue)
                            .cornerRadius(5)
                            .animation(.linear, value: viewModel.dailyGoalProgress)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Activity Calendar")
                .font(.headline)
                .padding(.horizontal)
            
            calendarGrid
                .padding(.horizontal, 5)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var calendarGrid: some View {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!) - 1
        
        return VStack(spacing: 10) {
            // Month name
            Text(DateFormatter().monthSymbols[currentMonth - 1])
                .font(.headline)
                .padding(.bottom, 5)
            
            // Day names
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            let totalDays = firstWeekday + daysInMonth
            let rows = totalDays / 7 + (totalDays % 7 > 0 ? 1 : 0)
            
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<7, id: \.self) { column in
                        let day = row * 7 + column - firstWeekday + 1
                        if day > 0 && day <= daysInMonth {
                            calendarDayCell(day: day)
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    private func calendarDayCell(day: Int) -> some View {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let selectedDay = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day))!
        
        let isToday = calendar.isDateInToday(selectedDay)
        let isSelected = calendar.compare(viewModel.selectedDate, to: selectedDay, toGranularity: .day) == .orderedSame
        
        let hasBreaks = viewModel.calendarBreaks.keys.contains { date in
            calendar.compare(date, to: selectedDay, toGranularity: .day) == .orderedSame
        }
        
        return Button(action: {
            viewModel.selectDate(selectedDay)
        }) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : (hasBreaks ? Color.blue.opacity(0.2) : Color.clear))
                    .frame(width: 36, height: 36)
                
                if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }
                
                Text("\(day)")
                    .font(.callout)
                    .foregroundColor(isSelected ? .white : (hasBreaks ? .primary : .primary))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Selected Day Details Section
    
    private var selectedDayDetailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Date heading
            Text(viewModel.formattedDate(viewModel.selectedDate))
                .font(.headline)
            
            Divider()
            
            // No data message
            if viewModel.selectedDayBreaks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No activity recorded for this day")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Activity summary
                VStack(spacing: 12) {
                    // Completed breaks
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed breaks:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.selectedDayBreaks.filter(\.completed).count)")
                            .fontWeight(.semibold)
                    }
                    
                    // Calories burned
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Calories burned:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(viewModel.selectedDayCalories))")
                            .fontWeight(.semibold)
                    }
                    
                    // Exercise focus areas
                    if !viewModel.exercisesByFocusArea.isEmpty {
                        ForEach(FocusArea.allCases, id: \.self) { focusArea in
                            if let count = viewModel.exercisesByFocusArea[focusArea], count > 0 {
                                HStack {
                                    focusAreaIcon(focusArea)
                                        .foregroundColor(focusAreaColor(focusArea))
                                    Text("\(focusArea.rawValue.capitalized) exercises:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
                
                Divider()
                
                // Activity timeline
                Text("Activity Timeline")
                    .font(.headline)
                    .padding(.top, 5)
                
                ForEach(viewModel.selectedDayBreaks.sorted(by: { $0.scheduledTime < $1.scheduledTime })) { breakItem in
                    HStack(alignment: .top, spacing: 15) {
                        // Time
                        Text(formatTime(breakItem.scheduledTime))
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                        
                        // Status indicator
                        Circle()
                            .fill(breakItem.completed ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                            .padding(.top, 4)
                        
                        // Break details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(breakItem.completed ? "Break Completed" : "Break Missed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            if let exerciseId = breakItem.exerciseId,
                               let exercise = viewModel.selectedDayExercises.first(where: { $0.id == exerciseId }) {
                                Text("Exercise: \(exercise.name)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("Focus: \(exercise.focusArea.rawValue.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    if viewModel.selectedDayBreaks.last != breakItem {
                        Divider()
                            .padding(.leading, 85)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func focusAreaIcon(_ focusArea: FocusArea) -> some View {
        switch focusArea {
        case .eye:
            return Image(systemName: "eye")
        case .back:
            return Image(systemName: "figure.walk")
        case .wrist:
            return Image(systemName: "hand.raised")
        }
    }
    
    private func focusAreaColor(_ focusArea: FocusArea) -> Color {
        switch focusArea {
        case .eye:
            return .blue
        case .back:
            return .green
        case .wrist:
            return .orange
        }
    }
}

// MARK: - ProgressViewModel Extension

extension ProgressViewModel {
    // Function to update the reference to the AuthViewModel
    func updateAuthViewModel(_ newAuthViewModel: AuthViewModel) {
        // Store the reference to the AuthViewModel
        self.authViewModel = newAuthViewModel
    }
}

struct UserProgressView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProgressView()
                .environmentObject(AuthViewModel())
        }
    }
}
