// ExerciseLibraryView.swift

import SwiftUI

struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var searchText = ""
    @State private var showingDetail = false
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar - iOS native height
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                // Filter Picker - iOS Native Segmented Control
                Picker("Filter", selection: $viewModel.selectedFocusArea) {
                    Text("All").tag(nil as FocusArea?)
                    ForEach(FocusArea.allCases, id: \.self) { focusArea in
                        Text(focusArea.rawValue.capitalized).tag(focusArea as FocusArea?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 15)
                
                // Exercises List - Updated UI
                ZStack {
                    if viewModel.isLoading && viewModel.exercises.isEmpty {
                        VStack(spacing: 15) {
                            ForEach(0..<3, id: \.self) { _ in
                                ExerciseRowSkeletonModern()
                            }
                        }
                        .padding(.horizontal)
                    } else if searchResults.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 20) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No exercises found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(searchResults) { exercise in
                                    ExerciseRowModern(
                                        exercise: exercise,
                                        isInRoutine: viewModel.isExerciseInRoutine(exercise),
                                        toggleRoutine: {
                                            Task {
                                                await viewModel.toggleRoutine(exercise)
                                            }
                                        },
                                        onTap: {
                                            selectedExercise = exercise
                                        }
                                    )
                                }
                                
                                // Add bottom padding to ensure content doesn't hide behind tab bar
                                Color.clear
                                    .frame(height: 90) // Adjust based on tab bar height
                            }
                            .padding(.horizontal)
                        }
                        // This ensures the ScrollView takes all available space while respecting safe areas
                        .edgesIgnoringSafeArea([])
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let exercise = selectedExercise {
                            ExerciseDetailView(
                                exercise: exercise,
                                isInRoutine: viewModel.isExerciseInRoutine(exercise),
                                toggleRoutine: {
                                    Task {
                                        await viewModel.toggleRoutine(exercise)
                                    }
                                }
                            )
                        }
                    },
                    isActive: Binding(
                        get: { selectedExercise != nil },
                        set: { if !$0 { selectedExercise = nil } }
                    )
                ) {
                    EmptyView()
                }
            )
            .task {
                if viewModel.exercises.isEmpty {
                    await viewModel.fetchExercises()
                    await viewModel.fetchRoutines()
                }
            }
            .refreshable {
                await viewModel.fetchExercises()
                await viewModel.fetchRoutines()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8) // iOS-native search bar height
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var searchResults: [Exercise] {
        if searchText.isEmpty {
            return viewModel.filteredExercises
        } else {
            return viewModel.filteredExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.instructions.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}


struct ExerciseRowModern: View {
    let exercise: Exercise
    let isInRoutine: Bool
    let toggleRoutine: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Exercise icon based on focus area
                exerciseIcon
                    .frame(width: 60, height: 60)
                    .padding(.trailing, 10)
                
                // Exercise details
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exercise.instructions.prefix(50) + (exercise.instructions.count > 50 ? "..." : ""))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack(spacing: 10) {
                        // Duration with formatted time
                        Label(formattedDuration, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Focus area tag
                        focusAreaTag
                    }
                }
                
                Spacer()
                
                // Chevron or action button
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing, 5)
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Format the duration to show minutes and seconds
    private var formattedDuration: String {
        let minutes = exercise.duration / 60
        let seconds = exercise.duration % 60
        
        if minutes > 0 {
            if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(minutes)m"
            }
        } else {
            return "\(seconds)s"
        }
    }
    
    private var exerciseIcon: some View {
        Group {
            if let thumbnailImage = exercise.thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(focusAreaBackgroundColor.opacity(0.3))
                    
                    focusAreaIcon
                        .font(.system(size: 30))
                        .foregroundColor(focusAreaColor)
                }
            }
        }
    }
    
    private var focusAreaTag: some View {
        HStack(spacing: 4) {
            focusAreaIcon
                .font(.caption)
            
            Text(exercise.focusArea.rawValue.capitalized)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(focusAreaBackgroundColor.opacity(0.3))
        .foregroundColor(focusAreaColor)
        .cornerRadius(12)
    }
    
    private var focusAreaIcon: some View {
        switch exercise.focusArea {
        case .eye:
            return Image(systemName: "eye")
        case .back:
            return Image(systemName: "figure.walk")
        case .wrist:
            return Image(systemName: "hand.raised")
        }
    }
    
    private var focusAreaColor: Color {
        switch exercise.focusArea {
        case .eye:
            return .blue
        case .back:
            return .green
        case .wrist:
            return .purple
        }
    }
    
    private var focusAreaBackgroundColor: Color {
        switch exercise.focusArea {
        case .eye:
            return .blue
        case .back:
            return .green
        case .wrist:
            return .orange
        }
    }
}


struct ExerciseRowSkeletonModern: View {
    var body: some View {
        HStack {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .padding(.trailing, 10)
            
            // Exercise details placeholder
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 18)
                    .frame(width: 120)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                    .frame(width: 200)
                
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                        .frame(width: 60)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                        .frame(width: 50)
                }
            }
            
            Spacer()
            
            // Chevron placeholder
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 20, height: 20)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .redacted(reason: .placeholder)
    }
}

struct ExerciseLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseLibraryView()
    }
}




