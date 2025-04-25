// ExerciseLibraryView.swift
import SwiftUI

struct ExerciseLibraryView: View {
   @StateObject private var viewModel = ExerciseLibraryViewModel()
   @State private var searchText = ""
   @State private var selectedExercise: Exercise?
   @State private var sortOption: SortOption = .name
   @State private var showFilterSheet = false
   @State private var showNoConnectionAlert = false
   
   // New sort options enum
   enum SortOption: String, CaseIterable, Identifiable {
       case name = "Name (A-Z)"
       case duration = "Duration"
       case repetitions = "Repetitions"
       
       var id: String { self.rawValue }
   }
   
   var body: some View {
       NavigationView {
           VStack(spacing: 0) {
               // Search Bar with improved styling
               searchBar
                   .padding(.horizontal)
                   .padding(.top, 10)
                   .padding(.bottom, 10)
               
               HStack {
                   // Filter Picker - iOS Native Segmented Control
                   Picker("Filter", selection: $viewModel.selectedFocusArea) {
                       Text("All").tag(nil as FocusArea?)
                       ForEach(FocusArea.allCases, id: \.self) { focusArea in
                           Text(focusArea.rawValue.capitalized).tag(focusArea as FocusArea?)
                       }
                   }
                   .pickerStyle(SegmentedPickerStyle())
                   
                   // Sort button - using custom sheet instead of popover
                   Button(action: {
                       showFilterSheet = true
                   }) {
                       HStack(spacing: 4) {
                           Image(systemName: "arrow.up.arrow.down")
                           Text("Sort")
                               .font(.subheadline)
                       }
                       .foregroundColor(.blue)
                       .padding(.horizontal, 10)
                       .padding(.vertical, 6)
                       .background(Color.blue.opacity(0.1))
                       .cornerRadius(8)
                   }
               }
               .padding(.horizontal)
               .padding(.bottom, 15)
               
               // Exercises List with improved UI
               ZStack {
                   if viewModel.isLoading && viewModel.exercises.isEmpty {
                       VStack(spacing: 15) {
                           ForEach(0..<3, id: \.self) { _ in
                               ExerciseRowSkeletonModern()
                           }
                       }
                       .padding(.horizontal)
                   } else if sortedAndFilteredExercises.isEmpty && !viewModel.isLoading {
                       VStack(spacing: 20) {
                           Image(systemName: "figure.walk")
                               .font(.system(size: 50))
                               .foregroundColor(.gray.opacity(0.5))
                           
                           Text("No exercises found")
                               .font(.headline)
                               .foregroundColor(.gray)
                           
                           // Refresh button for better UX
                           Button(action: {
                               Task {
                                   await viewModel.fetchExercises()
                                   await viewModel.fetchRoutines()
                               }
                           }) {
                               Text("Refresh")
                                   .font(.subheadline)
                                   .foregroundColor(.white)
                                   .padding(.horizontal, 20)
                                   .padding(.vertical, 10)
                                   .background(Color.blue)
                                   .cornerRadius(8)
                           }
                       }
                       .frame(maxWidth: .infinity, maxHeight: .infinity)
                       .padding()
                   } else {
                       ScrollView {
                           LazyVStack(spacing: 15) {
                               ForEach(sortedAndFilteredExercises) { exercise in
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
                                   .frame(height: 90)
                           }
                           .padding(.horizontal)
                       }
                       .refreshable {
                           print("Refreshing exercise data...")
                           await viewModel.fetchExercises()
                           await viewModel.fetchRoutines()
                       }
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
               // Check if we need to load data
               if viewModel.exercises.isEmpty {
                   do {
                       print("Initial data load...")
                       await viewModel.fetchExercises()
                       await viewModel.fetchRoutines()
                   } catch {
                       print("Failed to load initial data: \(error.localizedDescription)")
                       showNoConnectionAlert = true
                   }
               }
           }
           .alert("Connection Error", isPresented: $showNoConnectionAlert) {
               Button("Retry") {
                   Task {
                       await viewModel.fetchExercises()
                       await viewModel.fetchRoutines()
                   }
               }
               Button("OK", role: .cancel) { }
           } message: {
               Text("Please check your internet connection and try again")
           }
           .alert("Error", isPresented: $viewModel.showError) {
               Button("OK") { viewModel.errorMessage = nil }
           } message: {
               Text(viewModel.errorMessage ?? "An unknown error occurred")
           }
           .sheet(isPresented: $showFilterSheet) {
               SortOptionsSheet(sortOption: $sortOption, closeAction: { showFilterSheet = false })
                   .presentationDetents([.height(300)])
           }
       }
       .accentColor(.blue)
   }
   
   private var searchBar: some View {
       HStack {
           Image(systemName: "magnifyingglass")
               .foregroundColor(.blue)
           
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
       .padding(.vertical, 8)
       .padding(.horizontal, 12)
       .background(Color(.systemGray6))
       .cornerRadius(10)
   }
   
   // Get sorted and filtered exercises based on search, filter and sort options
   private var sortedAndFilteredExercises: [Exercise] {
       let filtered = searchText.isEmpty ? viewModel.filteredExercises :
       viewModel.filteredExercises.filter { exercise in
           exercise.name.localizedCaseInsensitiveContains(searchText) ||
           exercise.instructions.localizedCaseInsensitiveContains(searchText)
       }
       
       // Apply sorting
       return filtered.sorted { first, second in
           switch sortOption {
           case .name:
               return first.name < second.name
           case .duration:
               return first.duration < second.duration
           case .repetitions:
               return first.repetitions < second.repetitions
           }
       }
   }
}

// Custom sort options sheet similar to the Article filter UI
struct SortOptionsSheet: View {
   @Binding var sortOption: ExerciseLibraryView.SortOption
   let closeAction: () -> Void
   
   var body: some View {
       VStack(spacing: 0) {
           // Header
           HStack {
               Button("Reset") {
                   sortOption = .name
               }
               .foregroundColor(.blue)
               
               Spacer()
               
               Text("Filter & Sort")
                   .font(.headline)
               
               Spacer()
               
               Button("Done") {
                   closeAction()
               }
               .foregroundColor(.blue)
           }
           .padding()
           .background(Color(.systemGray6).opacity(0.3))
           
           Divider()
           
           // Sort options
           VStack(alignment: .leading, spacing: 0) {
               Text("Sort By")
                   .font(.subheadline)
                   .foregroundColor(.gray)
                   .padding(.horizontal)
                   .padding(.vertical, 8)
               
            
               
               ForEach(ExerciseLibraryView.SortOption.allCases) { option in
                   HStack {
                       Text(option.rawValue)
                           .foregroundColor(.primary)
                       
                       Spacer()
                       
                       if sortOption == option {
                           Image(systemName: "checkmark")
                               .foregroundColor(.blue)
                       }
                   }
                   .contentShape(Rectangle())
                   .onTapGesture {
                       sortOption = option
                   }
                   .padding()
                   .background(sortOption == option ? Color.blue.opacity(0.1) : Color.clear)
                   
                   if option != ExerciseLibraryView.SortOption.allCases.last {
                       Divider()
                           .padding(.leading)
                   }
               }
           }
           .background(Color.white)
           
           Spacer()
       }
   }
}

// Updated ExerciseRowModern with better styling and animation
struct ExerciseRowModern: View {
   let exercise: Exercise
   let isInRoutine: Bool
   let toggleRoutine: () -> Void
   let onTap: () -> Void
   
   @State private var isPressed: Bool = false
   
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
                       
                       // Routine indicator
                       if isInRoutine {
                           HStack(spacing: 2) {
                               Image(systemName: "checkmark.circle.fill")
                                   .foregroundColor(.blue)
                               Text("In Routine")
                                   .font(.caption)
                                   .foregroundColor(.blue)
                           }
                           .padding(.horizontal, 6)
                           .padding(.vertical, 2)
                           .background(Color.blue.opacity(0.1))
                           .cornerRadius(8)
                       }
                   }
               }
               
               Spacer()
               
               // Chevron
               Image(systemName: "chevron.right")
                   .foregroundColor(.blue.opacity(0.7))
                   .padding(.trailing, 5)
           }
           .padding()
           .background(Color(.systemGray6).opacity(0.5))
           .cornerRadius(12)
           .overlay(
               RoundedRectangle(cornerRadius: 12)
                   .stroke(isInRoutine ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
           )
           .scaleEffect(isPressed ? 0.98 : 1.0)
           .animation(.spring(response: 0.3), value: isPressed)
       }
       .buttonStyle(PlainButtonStyle())
       .simultaneousGesture(
           DragGesture(minimumDistance: 0)
               .onChanged { _ in
                   isPressed = true
               }
               .onEnded { _ in
                   isPressed = false
               }
       )
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
       .background(focusAreaBackgroundColor.opacity(0.2))
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

// Skeleton loader for better UX during loading
struct ExerciseRowSkeletonModern: View {
   var body: some View {
       HStack {
           // Icon placeholder
           RoundedRectangle(cornerRadius: 10)
               .fill(Color(.systemGray5))
               .frame(width: 60, height: 60)
               .padding(.trailing, 10)
               .shimmer(isActive: true)
           
           // Exercise details placeholder
           VStack(alignment: .leading, spacing: 8) {
               RoundedRectangle(cornerRadius: 4)
                   .fill(Color(.systemGray5))
                   .frame(height: 18)
                   .frame(width: 120)
                   .shimmer(isActive: true)
               
               RoundedRectangle(cornerRadius: 4)
                   .fill(Color(.systemGray5))
                   .frame(height: 14)
                   .frame(width: 200)
                   .shimmer(isActive: true)
               
               HStack(spacing: 10) {
                   RoundedRectangle(cornerRadius: 4)
                       .fill(Color(.systemGray5))
                       .frame(height: 12)
                       .frame(width: 60)
                       .shimmer(isActive: true)
                   
                   RoundedRectangle(cornerRadius: 4)
                       .fill(Color(.systemGray5))
                       .frame(height: 12)
                       .frame(width: 50)
                       .shimmer(isActive: true)
               }
           }
           
           Spacer()
           
           // Chevron placeholder
           Circle()
               .fill(Color(.systemGray5))
               .frame(width: 20, height: 20)
               .shimmer(isActive: true)
       }
       .padding()
       .background(Color(.systemGray6).opacity(0.3))
       .cornerRadius(12)
   }
}

// Shimmer effect for loading skeletons
struct ShimmerModifier: ViewModifier {
   let isActive: Bool
   @State private var phase: CGFloat = 0
   
   func body(content: Content) -> some View {
       if isActive {
           content
               .overlay(
                   GeometryReader { geo in
                       LinearGradient(
                           gradient: Gradient(stops: [
                               .init(color: .clear, location: phase - 0.3),
                               .init(color: .white.opacity(0.5), location: phase),
                               .init(color: .clear, location: phase + 0.3)
                           ]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing
                       )
                       .mask(Rectangle().frame(width: geo.size.width * 3))
                       .offset(x: -2 * geo.size.width + phase * 3 * geo.size.width)
                   }
               )
               .onAppear {
                   withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                       self.phase = 1
                   }
               }
       } else {
           content
       }
   }
}

extension View {
   func shimmer(isActive: Bool) -> some View {
       modifier(ShimmerModifier(isActive: isActive))
   }
}
