// ExerciseDetailView.swift
import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    let isInRoutine: Bool
    let toggleRoutine: () -> Void
    
    @State private var showingFullImage: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with thumbnail
                headerView
                
                // Details
                detailsView
                
                // Instructions
                instructionsView
                
                // Action button
                routineButton
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleRoutine) {
                    Image(systemName: isInRoutine ? "minus.circle" : "plus.circle")
                        .foregroundColor(isInRoutine ? .red : .blue)
                }
            }
            
        }
        .sheet(isPresented: $showingFullImage) {
            if let image = exercise.thumbnailImage {
                fullScreenImageView(image)
            }
        }
    }
    
    private var headerView: some View {
        ZStack(alignment: .bottom) {
            if let thumbnailImage = exercise.thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .onTapGesture {
                        showingFullImage = true
                    }
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "figure.walk")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
            }
            
            HStack {
                Text(exercise.focusArea.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(focusAreaColor(for: exercise.focusArea))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("\(exercise.duration)s")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.title)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(exercise.duration) seconds", systemImage: "clock")
                    Spacer()
                    Label("\(exercise.repetitions) repetitions", systemImage: "repeat")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                HStack {
                    Label("MET Score: \(String(format: "%.1f", exercise.metScore))", systemImage: "flame")
                    
                    if let user = try? AuthViewModel().user, let weight = user.weight {
                        Spacer()
                        let calories = exercise.caloriesBurned(weight: weight)
                        Label("\(String(format: "%.1f", calories)) calories", systemImage: "bolt")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)
            
            Text(exercise.instructions)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
    }
    
    private var routineButton: some View {
        Button(action: toggleRoutine) {
            HStack {
                Spacer()
                Image(systemName: isInRoutine ? "minus.circle.fill" : "plus.circle.fill")
                Text(isInRoutine ? "Remove from Routine" : "Add to Routine")
                Spacer()
            }
            .padding()
            .background(isInRoutine ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
            .foregroundColor(isInRoutine ? .red : .blue)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
    
    private func fullScreenImageView(_ image: UIImage) -> some View {
        VStack {
            HStack {
                Spacer()
                Button("Close") {
                    showingFullImage = false
                }
                .padding()
            }
            
            Spacer()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            
            Spacer()
        }
        .background(Color.black.opacity(0.8))
        .edgesIgnoringSafeArea(.all)
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
}

// Preview
struct ExerciseDetailView_Previews: PreviewProvider {
    static var sampleExercise = Exercise(
        id: UUID(),
        name: "20-20-20 Rule",
        instructions: "Every 20 minutes, look at something 20 feet away for 20 seconds to reduce eye strain.",
        thumbnailBase64: nil,
        duration: 20,
        repetitions: 3,
        focusArea: .eye,
        metScore: 1.5
    )
    
    static var previews: some View {
        ExerciseDetailView(
            exercise: sampleExercise,
            isInRoutine: true,
            toggleRoutine: {}
        )
    }
}
