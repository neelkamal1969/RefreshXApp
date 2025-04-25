//
//// HomeView.swift
//import SwiftUI
//
//struct HomeView: View {
//    @EnvironmentObject var authViewModel: AuthViewModel
//    @StateObject private var viewModel: HomeViewModel
//    @State private var greeting: String = ""
//    
//    init() {
//        // Initialize with a temporary AuthViewModel
//        // The real one will be injected via environmentObject
//        _viewModel = StateObject(wrappedValue: HomeViewModel(authViewModel: AuthViewModel()))
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // Background color for the entire view - default white
//                Color(.systemBackground)
//                    .ignoresSafeArea()
//                
//                VStack(spacing: 0) {
//                    // Fixed content at the top (greeting and timer card)
//                    VStack(spacing: 20) {
//                        // Custom greeting text view at the top
//                        VStack(alignment: .leading, spacing: 5) {
//                            Text(greeting.components(separatedBy: "\n").first ?? "")
//                                .font(.title)
//                                .fontWeight(.bold)
//                            
//                            if let secondLine = greeting.components(separatedBy: "\n").last,
//                               greeting.contains("\n") {
//                                Text(secondLine)
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.horizontal, 4)
//                        .padding(.bottom, 10)
//                        
//                        // Break Timer Card
//                        breakTimerCard
//                        
//                        // "Your Routine" title section
//                        HStack {
//                            Text("Your Routine")
//                                .font(.title3)
//                                .fontWeight(.bold)
//                            
//                            Spacer()
//                            
//                            if viewModel.isLoadingRoutine {
//                                ProgressView()
//                                    .scaleEffect(0.8)
//                            } else if !viewModel.isBreakActive {
//                                Button(action: {
//                                    viewModel.showExercisePicker = true
//                                }) {
//                                    Label("Add", systemImage: "plus.circle")
//                                        .font(.subheadline)
//                                        .foregroundColor(.blue)
//                                }
//                            }
//                        }
//                        .padding(.top, 10)
//                    }
//                    .padding(.horizontal)
//                    .padding(.top)
//                    
//                    // Scrollable content below (routine exercises)
//                    ScrollView {
//                        VStack(spacing: 20) {
//                            // Loading indicator if needed
//                            if viewModel.isLoadingRoutine {
//                                HStack {
//                                    Spacer()
//                                    ProgressView()
//                                        .padding()
//                                    Spacer()
//                                }
//                            }
//                            
//                            // Routine exercises content
//                            if !viewModel.routineExercises.isEmpty {
//                                // Group exercises by focus area
//                                let eyeExercises = viewModel.routineExercises.filter { $0.focusArea == .eye }
//                                let backExercises = viewModel.routineExercises.filter { $0.focusArea == .back }
//                                let wristExercises = viewModel.routineExercises.filter { $0.focusArea == .wrist }
//                                
//                                // Eye exercises section
//                                if !eyeExercises.isEmpty {
//                                    focusAreaSection(title: "Eye Exercises", icon: "eye", color: .blue, exercises: eyeExercises)
//                                }
//                                
//                                // Back exercises section
//                                if !backExercises.isEmpty {
//                                    focusAreaSection(title: "Back Exercises", icon: "figure.walk", color: .green, exercises: backExercises)
//                                }
//                                
//                                // Wrist exercises section
//                                if !wristExercises.isEmpty {
//                                    focusAreaSection(title: "Wrist Exercises", icon: "hand.raised", color: .orange, exercises: wristExercises)
//                                }
//                            }
//                            
//                            // No Routine Exercises Message
//                            if viewModel.routineExercises.isEmpty && !viewModel.isLoadingRoutine {
//                                noRoutineExercisesMessage
//                            }
//                        }
//                        .padding()
//                    }
//                }
//            }
//            .navigationTitle("")
//            .navigationBarHidden(true)
//            .sheet(isPresented: $viewModel.showExercisePicker) {
//                exercisePickerView
//            }
//            .fullScreenCover(isPresented: .init(
//                get: { viewModel.isBreakActive },
//                set: { if !$0 { Task { await viewModel.endBreak() } } }
//            )) {
//                breakSessionView
//            }
//            .onAppear {
//                // Update the viewModel with the current authViewModel
//                viewModel.authViewModel = authViewModel
//                
//                // Set greeting based on time of day
//                updateGreeting()
//                
//                // Load data on appearance
//                Task {
//                    await viewModel.loadData()
//                }
//            }
//            .onChange(of: authViewModel.user) { _ in
//                // Reload data if user changes
//                Task {
//                    await viewModel.loadData()
//                }
//            }
//            .refreshable {
//                await viewModel.loadData()
//            }
//            .alert("Error", isPresented: $viewModel.showError) {
//                Button("OK") { viewModel.errorMessage = nil }
//            } message: {
//                Text(viewModel.errorMessage ?? "An unknown error occurred")
//            }
//        }
//    }
//    
//    // MARK: - Break Timer Card
//    
//    private var breakTimerCard: some View {
//        VStack(spacing: 15) {
//            // Next Break Time Info with improved visibility
//            Text(viewModel.nextBreakTime)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.secondary)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding(.top, 5)
//            
//            // Improved Timer Display with card appearance
//            ZStack {
//                // Background with subtle gradient
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.15)]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(height: 110)
//                
//                // Time display with shadow for depth
//                Text(viewModel.formattedTime(seconds: viewModel.remainingBreakTime))
//                    .font(.system(size: 64, weight: .semibold, design: .rounded))
//                    .monospacedDigit()
//                    .foregroundColor(.blue)
//                    .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
//                    .padding()
//            }
//            .padding(.vertical, 5)
//            
//            // Start/End Break Button with improved appearance
//            Button(action: {
//                if viewModel.isBreakActive {
//                    Task {
//                        await viewModel.endBreak()
//                    }
//                } else {
//                    Task {
//                        await viewModel.startBreak()
//                    }
//                }
//            }) {
//                Text(viewModel.isBreakActive ? "End Break" : "Start Break")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 14)
//                    .background(
//                        viewModel.isBreakActive
//                            ? LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
//                            : LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
//                    )
//                    .cornerRadius(15)
//                    .shadow(color: viewModel.isBreakActive ? Color.red.opacity(0.3) : Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6)) // Changed from white to gray
//        .cornerRadius(20)
//        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
//    }
//    
//    // MARK: - Exercise Card Design
//    
//    private func focusAreaSection(title: String, icon: String, color: Color, exercises: [Exercise]) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Section header with improved styling
//            HStack {
//                Image(systemName: icon)
//                    .foregroundColor(color)
//                    .font(.system(size: 18, weight: .semibold))
//                
//                Text(title)
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                    .foregroundColor(color)
//            }
//            .padding(.horizontal, 4)
//            .padding(.top, 4)
//            .padding(.bottom, 2)
//            
//            // Exercises in this focus area
//            ForEach(exercises) { exercise in
//                routineExerciseCard(exercise)
//            }
//        }
//    }
//    
//    private func routineExerciseCard(_ exercise: Exercise) -> some View {
//        NavigationLink(destination: ExerciseDetailView(
//            exercise: exercise,
//            isInRoutine: true,
//            toggleRoutine: {
//                Task {
//                    await viewModel.removeExerciseFromRoutine(at: [viewModel.routineExercises.firstIndex(where: { $0.id == exercise.id })!])
//                }
//            }
//        )) {
//            HStack(spacing: 12) {
//                // Exercise thumbnail
//                Group {
//                    if let thumbnailImage = exercise.thumbnailImage {
//                        Image(uiImage: thumbnailImage)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 70, height: 70)
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                    } else {
//                        // Placeholder icon based on focus area
//                        ZStack {
//                            RoundedRectangle(cornerRadius: 8)
//                                .fill(Color(.systemGray5))
//                            
//                            Image(systemName: focusAreaIconName(for: exercise.focusArea))
//                                .font(.system(size: 30))
//                                .foregroundColor(Color(.systemGray))
//                        }
//                        .frame(width: 70, height: 70)
//                    }
//                }
//                
//                // Exercise details
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(exercise.name)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    // Brief instruction text
//                    Text(exerciseInstructionSummary(for: exercise))
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                    
//                    HStack {
//                        // Duration with icon
//                        HStack(spacing: 4) {
//                            Image(systemName: "clock")
//                                .font(.caption2)
//                            Text("\(exercise.duration)s")
//                                .font(.caption)
//                        }
//                        .foregroundColor(.gray)
//                        .padding(.trailing, 8)
//                        
//                        // Focus area tag with color
//                        focusAreaTag(for: exercise.focusArea)
//                    }
//                }
//                
//                Spacer()
//                
//                // Chevron
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//                    .font(.caption)
//                    .padding(.trailing, 4)
//            }
//            .padding(12)
//            .background(Color(.systemGray6)) // Changed from white to gray
//            .cornerRadius(12)
//            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
//        }
//        .buttonStyle(PlainButtonStyle())
//        .swipeActions(edge: .trailing) {
//            Button(role: .destructive) {
//                Task {
//                    await viewModel.removeExerciseFromRoutine(at: [viewModel.routineExercises.firstIndex(where: { $0.id == exercise.id })!])
//                }
//            } label: {
//                Label("Remove", systemImage: "trash")
//            }
//        }
//    }
//    
//    private func focusAreaTag(for focusArea: FocusArea) -> some View {
//        HStack(spacing: 4) {
//            Image(systemName: focusAreaIconName(for: focusArea))
//                .font(.caption2)
//            
//            Text(focusArea.rawValue.capitalized)
//                .font(.caption)
//                .fontWeight(.medium)
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//        .background(focusAreaColor(for: focusArea).opacity(0.2))
//        .foregroundColor(focusAreaColor(for: focusArea))
//        .cornerRadius(12)
//    }
//    
//    private func exerciseInstructionSummary(for exercise: Exercise) -> String {
//        // Create a brief summary of the instructions
//        let instructions = exercise.instructions
//        let words = instructions.split(separator: " ")
//        let firstFewWords = words.prefix(5).joined(separator: " ")
//        return firstFewWords + (words.count > 5 ? "..." : "")
//    }
//    
//    private func focusAreaIconName(for focusArea: FocusArea) -> String {
//        switch focusArea {
//        case .eye:
//            return "eye"
//        case .back:
//            return "figure.walk"
//        case .wrist:
//            return "hand.raised"
//        }
//    }
//    
//    private func focusAreaColor(for focusArea: FocusArea) -> Color {
//        switch focusArea {
//        case .eye:
//            return .blue
//        case .back:
//            return .green
//        case .wrist:
//            return .orange
//        }
//    }
//    
//    private var noRoutineExercisesMessage: some View {
//        VStack(spacing: 24) {
//            // Larger icon with subtle shadow
//            Image(systemName: "figure.walk")
//                .font(.system(size: 56))
//                .foregroundColor(.gray.opacity(0.7))
//                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
//                .padding(.bottom, 8)
//            
//            Text("No exercises in your routine")
//                .font(.title3)
//                .fontWeight(.semibold)
//                .foregroundColor(.gray)
//            
//            Text("Add exercises to your routine to get started")
//                .font(.subheadline)
//                .foregroundColor(.gray)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//                .padding(.bottom, 8)
//            
//            // Improved button with gradient
//            Button(action: {
//                viewModel.showExercisePicker = true
//            }) {
//                HStack {
//                    Image(systemName: "plus.circle.fill")
//                        .font(.headline)
//                    Text("Add Exercises")
//                        .font(.headline)
//                }
//                .foregroundColor(.white)
//                .padding(.vertical, 14)
//                .padding(.horizontal, 24)
//                .background(
//                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
//                )
//                .cornerRadius(14)
//                .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
//            }
//        }
//        .padding(.vertical, 40)
//        .padding(.horizontal, 20)
//        .frame(maxWidth: .infinity)
//        .background(Color(.systemGray6)) // Changed from white to gray
//        .cornerRadius(20)
//    }
//    
//    // MARK: - Exercise Picker View
//    
//    private var exercisePickerView: some View {
//        NavigationStack {
//            ZStack {
//                // Background color for the sheet
//                Color(.systemGray6)
//                    .ignoresSafeArea()
//                
//                VStack {
//                    if viewModel.availableExercises.isEmpty {
//                        VStack(spacing: 20) {
//                            ProgressView()
//                                .scaleEffect(1.2)
//                                .padding()
//                            
//                            Text("Loading available exercises...")
//                                .font(.headline)
//                                .foregroundColor(.gray)
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    } else {
//                        List {
//                            ForEach(viewModel.availableExercises) { exercise in
//                                Button(action: {
//                                    Task {
//                                        await viewModel.addExerciseToRoutine(exercise)
//                                    }
//                                }) {
//                                    // Use the same card design as in the routine list
//                                    HStack(spacing: 12) {
//                                        // Exercise thumbnail
//                                        Group {
//                                            if let thumbnailImage = exercise.thumbnailImage {
//                                                Image(uiImage: thumbnailImage)
//                                                    .resizable()
//                                                    .scaledToFill()
//                                                    .frame(width: 70, height: 70)
//                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                                            } else {
//                                                // Placeholder icon based on focus area
//                                                ZStack {
//                                                    RoundedRectangle(cornerRadius: 8)
//                                                        .fill(Color(.systemGray5))
//                                                    
//                                                    Image(systemName: focusAreaIconName(for: exercise.focusArea))
//                                                        .font(.system(size: 30))
//                                                        .foregroundColor(Color(.systemGray))
//                                                }
//                                                .frame(width: 70, height: 70)
//                                            }
//                                        }
//                                        
//                                        // Exercise details
//                                        VStack(alignment: .leading, spacing: 4) {
//                                            Text(exercise.name)
//                                                .font(.headline)
//                                                .foregroundColor(.primary)
//                                            
//                                            // Brief instruction text
//                                            Text(exerciseInstructionSummary(for: exercise))
//                                                .font(.subheadline)
//                                                .foregroundColor(.secondary)
//                                                .lineLimit(1)
//                                            
//                                            HStack {
//                                                // Duration with icon
//                                                HStack(spacing: 4) {
//                                                    Image(systemName: "clock")
//                                                        .font(.caption2)
//                                                    Text("\(exercise.duration)s")
//                                                        .font(.caption)
//                                                }
//                                                .foregroundColor(.gray)
//                                                .padding(.trailing, 8)
//                                                
//                                                // Focus area tag with color
//                                                focusAreaTag(for: exercise.focusArea)
//                                            }
//                                        }
//                                        
//                                        Spacer()
//                                        
//                                        // Add icon
//                                        Image(systemName: "plus.circle.fill")
//                                            .foregroundColor(.blue)
//                                            .font(.title3)
//                                    }
//                                    .padding(.vertical, 8)
//                                }
//                                .listRowBackground(Color(.systemGray6)) // Gray background for list rows
//                            }
//                        }
//                        .listStyle(PlainListStyle())
//                        .background(Color(.systemGray6))
//                    }
//                }
//            }
//            .navigationTitle("Add to Routine")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        viewModel.showExercisePicker = false
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        viewModel.showExercisePicker = false
//                    }
//                }
//            }
//            .onAppear {
//                // Fetch available exercises when sheet appears
//                Task {
//                    await viewModel.fetchAvailableExercises()
//                }
//            }
//        }
//    }
//    
//    // MARK: - Break Session View
//    
//    private var breakSessionView: some View {
//        ZStack {
//            // Background color
//            Color(.systemGray6).edgesIgnoringSafeArea(.all) // Changed from white to gray
//            
//            VStack(spacing: 20) {
//                // Top navigation bar
//                HStack {
//                    Button(action: {
//                        Task {
//                            await viewModel.endBreak()
//                        }
//                    }) {
//                        Text("End Break")
//                            .foregroundColor(.red)
//                            .padding(10)
//                            .background(Color.red.opacity(0.1))
//                            .cornerRadius(8)
//                    }
//                    
//                    Spacer()
//                    
//                    // Timer display
//                    Text("Break: \(viewModel.formattedTime(seconds: viewModel.remainingBreakTime))")
//                        .font(.headline)
//                        .foregroundColor(.blue)
//                        .padding(10)
//                        .background(Color.blue.opacity(0.1))
//                        .cornerRadius(8)
//                }
//                .padding(.horizontal)
//                .padding(.top, 16)
//                
//                Spacer()
//                
//                // Current exercise info
//                if let currentExercise = viewModel.routineExercises[safe: viewModel.selectedExerciseIndex] {
//                    // Exercise thumbnail
//                    if let thumbnailImage = currentExercise.thumbnailImage {
//                        Image(uiImage: thumbnailImage)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(maxWidth: 200, maxHeight: 200)
//                            .cornerRadius(15)
//                            .padding()
//                    } else {
//                        Image(systemName: focusAreaIconName(for: currentExercise.focusArea))
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 100, height: 100)
//                            .foregroundColor(focusAreaColor(for: currentExercise.focusArea))
//                            .padding(50)
//                            .background(focusAreaColor(for: currentExercise.focusArea).opacity(0.1))
//                            .cornerRadius(15)
//                    }
//                    
//                    // Exercise name
//                    Text(currentExercise.name)
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal)
//                    
//                    // Exercise details
//                    VStack(spacing: 10) {
//                        Text("\(currentExercise.duration) seconds")
//                            .font(.headline)
//                        
//                        Text("\(currentExercise.repetitions) repetitions")
//                            .font(.headline)
//                        
//                        Text(currentExercise.focusArea.rawValue.capitalized)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                            .padding(.vertical, 5)
//                            .padding(.horizontal, 20)
//                            .background(Color(.systemGray5))
//                            .cornerRadius(20)
//                    }
//                    .padding()
//                    
//                    // Exercise instructions
//                    ScrollView {
//                        Text(currentExercise.instructions)
//                            .font(.body)
//                            .padding()
//                            .background(Color(.systemGray5))
//                            .cornerRadius(10)
//                            .padding(.horizontal)
//                    }
//                    .frame(maxHeight: 150)
//                    
//                    Spacer()
//                    
//                    // Navigation controls
//                    HStack(spacing: 40) {
//                        // Previous button
//                        Button(action: {
//                            viewModel.moveToPreviousExercise()
//                        }) {
//                            VStack {
//                                Image(systemName: "arrow.left.circle.fill")
//                                    .font(.system(size: 40))
//                                Text("Previous")
//                                    .font(.caption)
//                            }
//                        }
//                        .foregroundColor(viewModel.selectedExerciseIndex > 0 ? .blue : .gray)
//                        .disabled(viewModel.selectedExerciseIndex == 0)
//                        
//                        // Complete button
//                        Button(action: {
//                            Task {
//                                await viewModel.markExerciseComplete()
//                            }
//                        }) {
//                            VStack {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .font(.system(size: 40))
//                                Text("Complete")
//                                    .font(.caption)
//                            }
//                        }
//                        .foregroundColor(.green)
//                        
//                        // Next button
//                        Button(action: {
//                            viewModel.moveToNextExercise()
//                        }) {
//                            VStack {
//                                Image(systemName: "arrow.right.circle.fill")
//                                    .font(.system(size: 40))
//                                Text("Next")
//                                    .font(.caption)
//                            }
//                        }
//                        .foregroundColor(viewModel.selectedExerciseIndex < viewModel.routineExercises.count - 1 ? .blue : .gray)
//                        .disabled(viewModel.selectedExerciseIndex >= viewModel.routineExercises.count - 1)
//                    }
//                    .padding(.bottom, 40)
//                } else {
//                    Text("No exercises in your routine")
//                        .font(.title2)
//                        .foregroundColor(.gray)
//                    
//                    Button(action: {
//                        Task {
//                            await viewModel.endBreak()
//                        }
//                    }) {
//                        Text("End Break")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.red)
//                            .cornerRadius(10)
//                    }
//                    
//                    Spacer()
//                }
//            }
//            .padding(.bottom, 30)
//        }
//    }
//    
//    // MARK: - Helper Functions
//    
//    private func updateGreeting() {
//        let hour = Calendar.current.component(.hour, from: Date())
//        
//        switch hour {
//        case 0..<5:
//            greeting = "Good night"
//        case 5..<12:
//            greeting = "Good morning"
//        case 12..<17:
//            greeting = "Good afternoon"
//        default:
//            greeting = "Good evening"
//        }
//        
//        if let user = authViewModel.user {
//            let firstName = user.name.components(separatedBy: " ").first ?? user.name
//            greeting += ", \(firstName)"
//            greeting += "\nTime for a refreshing break!"
//        } else {
//            greeting += "\nWelcome to RefreshX"
//        }
//    }
//}
//
//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            HomeView()
//                .environmentObject(AuthViewModel())
//        }
//    }
//}
// HomeView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: HomeViewModel
    @State private var greeting: String = ""
    
    init() {
        // Initialize with a temporary AuthViewModel
        // The real one will be injected via environmentObject
        _viewModel = StateObject(wrappedValue: HomeViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color for the entire view - default white
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed content at the top (greeting and timer card)
                    VStack(spacing: 20) {
                        // Custom greeting text view at the top
                        VStack(alignment: .leading, spacing: 5) {
                            Text(greeting.components(separatedBy: "\n").first ?? "")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let secondLine = greeting.components(separatedBy: "\n").last,
                               greeting.contains("\n") {
                                Text(secondLine)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 10)
                        
                        // Break Timer Card
                        breakTimerCard
                        
                        // "Your Routine" title section
                        HStack {
                            Text("Your Routine")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if viewModel.isLoadingRoutine {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if !viewModel.isBreakActive {
                                Button(action: {
                                    viewModel.showExercisePicker = true
                                }) {
                                    Label("Add", systemImage: "plus.circle")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Scrollable content below (routine exercises)
                    ScrollView {
                        VStack(spacing: 20) {
                            // Loading indicator if needed
                            if viewModel.isLoadingRoutine {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            }
                            
                            // Routine exercises content
                            if !viewModel.routineExercises.isEmpty {
                                // Group exercises by focus area
                                let eyeExercises = viewModel.routineExercises.filter { $0.focusArea == .eye }
                                let backExercises = viewModel.routineExercises.filter { $0.focusArea == .back }
                                let wristExercises = viewModel.routineExercises.filter { $0.focusArea == .wrist }
                                
                                // Eye exercises section
                                if !eyeExercises.isEmpty {
                                    focusAreaSection(title: "Eye Exercises", icon: "eye", color: .blue, exercises: eyeExercises)
                                }
                                
                                // Back exercises section
                                if !backExercises.isEmpty {
                                    focusAreaSection(title: "Back Exercises", icon: "figure.walk", color: .green, exercises: backExercises)
                                }
                                
                                // Wrist exercises section
                                if !wristExercises.isEmpty {
                                    focusAreaSection(title: "Wrist Exercises", icon: "hand.raised", color: .orange, exercises: wristExercises)
                                }
                            }
                            
                            // No Routine Exercises Message
                            if viewModel.routineExercises.isEmpty && !viewModel.isLoadingRoutine {
                                noRoutineExercisesMessage
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showExercisePicker) {
                exercisePickerView
            }
            .fullScreenCover(isPresented: .init(
                get: { viewModel.isBreakActive },
                set: { if !$0 { Task { await viewModel.endBreak() } } }
            )) {
                breakSessionView
            }
            .onAppear {
                // Update the viewModel with the current authViewModel
                viewModel.authViewModel = authViewModel
                
                // Set greeting based on time of day
                updateGreeting()
                
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
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Break Timer Card
        
    private var breakTimerCard: some View {
        VStack(spacing: 8) {  // Reduced spacing from 15 to 8
            // Next Break Time Info with improved visibility
            Text(viewModel.nextBreakTime)
                .font(.footnote)  // Changed from subheadline to footnote
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)  // Reduced from 5 to 2
            
            // Improved Timer Display with card appearance - more compact
            ZStack {
                // Background with subtle gradient
                RoundedRectangle(cornerRadius: 16)  // Reduced from 20 to 16
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.15)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)  // Reduced from 110 to 80
                
                // Time display with shadow for depth
                Text(viewModel.formattedTime(seconds: viewModel.remainingBreakTime))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))  // Reduced from 64 to 48
                    .monospacedDigit()
                    .foregroundColor(.blue)
                    .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.vertical, 2)  // Reduced padding
            }
            .padding(.vertical, 2)  // Reduced from 5 to 2
            
            // Start/End Break Button with improved appearance
            Button(action: {
                if viewModel.isBreakActive {
                    Task {
                        await viewModel.endBreak()
                    }
                } else {
                    Task {
                        await viewModel.startBreak()
                    }
                }
            }) {
                Text(viewModel.isBreakActive ? "End Break" : "Start Break")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)  // Reduced from 14 to 10
                    .background(
                        viewModel.isBreakActive
                            ? LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                            : LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(12)  // Reduced from 15 to 12
                    .shadow(color: viewModel.isBreakActive ? Color.red.opacity(0.3) : Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)  // Reduced shadow
            }
        }
        .padding(12)  // Reduced from 16 to 12
        .background(Color(.systemGray6))
        .cornerRadius(16)  // Reduced from 20 to 16
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)  // Reduced shadow
    }
    // MARK: - Exercise Card Design
    
    private func focusAreaSection(title: String, icon: String, color: Color, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with improved styling
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 2)
            
            // Exercises in this focus area
            ForEach(exercises) { exercise in
                routineExerciseCard(exercise)
            }
        }
    }
    
    private func routineExerciseCard(_ exercise: Exercise) -> some View {
        NavigationLink(destination: ExerciseDetailView(
            exercise: exercise,
            isInRoutine: true,
            toggleRoutine: {
                Task {
                    await viewModel.removeExerciseFromRoutine(at: [viewModel.routineExercises.firstIndex(where: { $0.id == exercise.id })!])
                }
            }
        )) {
            HStack(spacing: 12) {
                // Exercise thumbnail
                Group {
                    if let thumbnailImage = exercise.thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Placeholder icon based on focus area
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                            
                            Image(systemName: focusAreaIconName(for: exercise.focusArea))
                                .font(.system(size: 30))
                                .foregroundColor(Color(.systemGray))
                        }
                        .frame(width: 70, height: 70)
                    }
                }
                
                // Exercise details
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Brief instruction text
                    Text(exerciseInstructionSummary(for: exercise))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        // Duration with icon
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("\(exercise.duration)s")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                        
                        // Focus area tag with color
                        focusAreaTag(for: exercise.focusArea)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .padding(.trailing, 4)
            }
            .padding(12)
            .background(Color(.systemGray6)) // Changed from white to gray
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    await viewModel.removeExerciseFromRoutine(at: [viewModel.routineExercises.firstIndex(where: { $0.id == exercise.id })!])
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    private func focusAreaTag(for focusArea: FocusArea) -> some View {
        HStack(spacing: 4) {
            Image(systemName: focusAreaIconName(for: focusArea))
                .font(.caption2)
            
            Text(focusArea.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(focusAreaColor(for: focusArea).opacity(0.2))
        .foregroundColor(focusAreaColor(for: focusArea))
        .cornerRadius(12)
    }
    
    private func exerciseInstructionSummary(for exercise: Exercise) -> String {
        // Create a brief summary of the instructions
        let instructions = exercise.instructions
        let words = instructions.split(separator: " ")
        let firstFewWords = words.prefix(5).joined(separator: " ")
        return firstFewWords + (words.count > 5 ? "..." : "")
    }
    
    private func focusAreaIconName(for focusArea: FocusArea) -> String {
        switch focusArea {
        case .eye:
            return "eye"
        case .back:
            return "figure.walk"
        case .wrist:
            return "hand.raised"
        }
    }
    
    private func focusAreaColor(for focusArea: FocusArea) -> Color {
        switch focusArea {
        case .eye:
            return .blue
        case .back:
            return .green
        case .wrist:
            return .orange
        }
    }
    
    private var noRoutineExercisesMessage: some View {
        VStack(spacing: 24) {
            // Larger icon with subtle shadow
            Image(systemName: "figure.walk")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.bottom, 8)
            
            Text("No exercises in your routine")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text("Add exercises to your routine to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Improved button with gradient
            Button(action: {
                viewModel.showExercisePicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text("Add Exercises")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6)) // Changed from white to gray
        .cornerRadius(20)
    }
    
    // MARK: - Exercise Picker View
    
    private var exercisePickerView: some View {
        NavigationStack {
            ZStack {
                // Background color for the sheet
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack {
                    if viewModel.availableExercises.isEmpty {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding()
                            
                            Text("Loading available exercises...")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.availableExercises) { exercise in
                                Button(action: {
                                    Task {
                                        await viewModel.addExerciseToRoutine(exercise)
                                    }
                                }) {
                                    // Use the same card design as in the routine list
                                    HStack(spacing: 12) {
                                        // Exercise thumbnail
                                        Group {
                                            if let thumbnailImage = exercise.thumbnailImage {
                                                Image(uiImage: thumbnailImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 70, height: 70)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } else {
                                                // Placeholder icon based on focus area
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color(.systemGray5))
                                                    
                                                    Image(systemName: focusAreaIconName(for: exercise.focusArea))
                                                        .font(.system(size: 30))
                                                        .foregroundColor(Color(.systemGray))
                                                }
                                                .frame(width: 70, height: 70)
                                            }
                                        }
                                        
                                        // Exercise details
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            // Brief instruction text
                                            Text(exerciseInstructionSummary(for: exercise))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            
                                            HStack {
                                                // Duration with icon
                                                HStack(spacing: 4) {
                                                    Image(systemName: "clock")
                                                        .font(.caption2)
                                                    Text("\(exercise.duration)s")
                                                        .font(.caption)
                                                }
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 8)
                                                
                                                // Focus area tag with color
                                                focusAreaTag(for: exercise.focusArea)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Add icon
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(Color(.systemGray6)) // Gray background for list rows
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color(.systemGray6))
                    }
                }
            }
            .navigationTitle("Add to Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showExercisePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showExercisePicker = false
                    }
                }
            }
            .onAppear {
                // Fetch available exercises when sheet appears
                Task {
                    await viewModel.fetchAvailableExercises()
                }
            }
        }
    }
    
    // MARK: - Break Session View
    
    private var breakSessionView: some View {
        ZStack {
            // Background color
            Color(.systemGray6).edgesIgnoringSafeArea(.all) // Changed from white to gray
            
            VStack(spacing: 20) {
                // Top navigation bar
                HStack {
                    Button(action: {
                        Task {
                            await viewModel.endBreak()
                        }
                    }) {
                        Text("End Break")
                            .foregroundColor(.red)
                            .padding(10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Timer display
                    Text("Break: \(viewModel.formattedTime(seconds: viewModel.remainingBreakTime))")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
                
                // Current exercise info
                if let currentExercise = viewModel.routineExercises[safe: viewModel.selectedExerciseIndex] {
                    // Exercise thumbnail
                    if let thumbnailImage = currentExercise.thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(15)
                            .padding()
                    } else {
                        Image(systemName: focusAreaIconName(for: currentExercise.focusArea))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(focusAreaColor(for: currentExercise.focusArea))
                            .padding(50)
                            .background(focusAreaColor(for: currentExercise.focusArea).opacity(0.1))
                            .cornerRadius(15)
                    }
                    
                    // Exercise name
                    Text(currentExercise.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Exercise details
                    VStack(spacing: 10) {
                        Text("\(currentExercise.duration) seconds")
                            .font(.headline)
                        
                        Text("\(currentExercise.repetitions) repetitions")
                            .font(.headline)
                        
                        Text(currentExercise.focusArea.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 20)
                            .background(Color(.systemGray5))
                            .cornerRadius(20)
                    }
                    .padding()
                    
                    // Exercise instructions
                    ScrollView {
                        Text(currentExercise.instructions)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 150)
                    
                    Spacer()
                    
                    // Navigation controls
                    HStack(spacing: 40) {
                        // Previous button
                        Button(action: {
                            viewModel.moveToPreviousExercise()
                        }) {
                            VStack {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.system(size: 40))
                                Text("Previous")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(viewModel.selectedExerciseIndex > 0 ? .blue : .gray)
                        .disabled(viewModel.selectedExerciseIndex == 0)
                        
                        // Complete button
                        Button(action: {
                            Task {
                                await viewModel.markExerciseComplete()
                            }
                        }) {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                Text("Complete")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.green)
                        
                        // Next button
                        Button(action: {
                            viewModel.moveToNextExercise()
                        }) {
                            VStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 40))
                                Text("Next")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(viewModel.selectedExerciseIndex < viewModel.routineExercises.count - 1 ? .blue : .gray)
                        .disabled(viewModel.selectedExerciseIndex >= viewModel.routineExercises.count - 1)
                    }
                    .padding(.bottom, 40)
                } else {
                    Text("No exercises in your routine")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        Task {
                            await viewModel.endBreak()
                        }
                    }) {
                        Text("End Break")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<5:
            greeting = "Good night"
        case 5..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        default:
            greeting = "Good evening"
        }
        
        if let user = authViewModel.user {
            let firstName = user.name.components(separatedBy: " ").first ?? user.name
            greeting += ", \(firstName)"
            greeting += "\nTime for a refreshing break!"
        } else {
            greeting += "\nWelcome to RefreshX"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(AuthViewModel())
        }
    }
}
