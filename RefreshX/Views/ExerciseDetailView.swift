// ExerciseDetailView.swift
import SwiftUI
import AVFoundation
import ObjectiveC

struct ExerciseDetailView: View {
    let exercise: Exercise
    let isInRoutine: Bool
    let toggleRoutine: () -> Void
    
    @State private var showingFullImage: Bool = false
    @State private var isShowingInfoOverlay: Bool = false
    @State private var infoType: InfoType = .met
    @State private var isPlaying: Bool = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var displayedQuote: String = ""
    @State private var isAnimatingHeader: Bool = false
    @State private var isInstructionsExpanded: Bool = false
    @State private var showTapPrompt: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    // Enhanced quotes and facts arrays with more options
    private let eyeQuotes = [
        "Your eyes blink around 15-20 times per minute—that's over 20,000 times a day!",
        "Looking at distant objects helps relax the focusing muscle inside your eye.",
        "The 20-20-20 rule: Every 20 minutes, look 20 feet away for 20 seconds.",
        "Blue light from screens can contribute to digital eye strain.",
        "The human eye can distinguish approximately 10 million different colors.",
        "Eye muscles are the most active muscles in the human body.",
        "On average, you blink 4,200,000 times a year.",
        "Your eyes remain the same size from birth, but your nose and ears never stop growing."
    ]
    
    private let backQuotes = [
        "Your spine supports your entire body but needs regular movement to stay healthy.",
        "Good posture helps avoid unnecessary strain on muscles and ligaments.",
        "Moving regularly throughout the day is more beneficial than a single workout.",
        "Even small stretches can increase blood flow to stiff muscles.",
        "The average person sits for about 12 hours each day, increasing strain on the back.",
        "The spine has a natural S-curve that acts as a shock absorber for your movements.",
        "Maintaining a strong core helps support your back and improve posture.",
        "Standing desks can reduce back pain by 32% according to some studies."
    ]
    
    private let wristQuotes = [
        "Your wrists contain eight small bones and numerous tendons that enable precise movements.",
        "Regular wrist stretches can help prevent carpal tunnel syndrome.",
        "Proper ergonomics can reduce wrist strain during computer work.",
        "Simple wrist rotations stimulate synovial fluid that lubricates your joints.",
        "The eight small bones in your wrist are called carpals, which connect to your fingers through metacarpals.",
        "Regular breaks from typing can reduce your risk of repetitive strain injuries by up to 60%.",
        "Using a wrist rest can help keep your wrists in a neutral position while typing.",
        "The median nerve, which runs through your wrist, controls sensation in your thumb, index, and middle fingers."
    ]
    
    enum InfoType {
        case met, duration, repetitions
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with thumbnail
                headerView
                
                // Details
                detailsView
                
                // Instructions with read aloud feature
                instructionsView
                
                // Motivational quote section
                quoteView
                
                // Know More button
                knowMoreButton
                
                // Action button
                routineButton
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            Group {
                if isShowingInfoOverlay {
                    customInfoOverlay
                }
            }
        )
        .onDisappear {
            // Stop speech when leaving view
            if isPlaying {
                speechSynthesizer.stopSpeaking(at: .immediate)
                isPlaying = false
            }
        }
        .onAppear {
            // Select random quote based on focus area
            displayedQuote = getRandomQuote()
            
            // Animate header
            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimatingHeader = true
            }
            
            // Show tap prompt after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showTapPrompt = true
                }
            }
            
            // Hide tap prompt after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    showTapPrompt = false
                }
            }
        }
        .sheet(isPresented: $showingFullImage) {
            if let image = exercise.thumbnailImage {
                fullScreenImageView(image)
            }
        }
    }
    
    private var customInfoOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowingInfoOverlay = false
                    }
                }
            
            VStack(spacing: 16) {
                // Header with icon
                HStack {
                    infoIcon
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text(infoType == .met ? "MET Score" : (infoType == .duration ? "Duration" : "Repetitions"))
                        .font(.headline)
                }
                .padding(.top)
                
                Text(getInfoDescription())
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation(.spring()) {
                        isShowingInfoOverlay = false
                    }
                }) {
                    Text("Got it")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 100)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: 300)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            .transition(.scale)
        }
    }
    
    private var infoIcon: some View {
        switch infoType {
        case .met:
            return Image(systemName: "flame.fill")
        case .duration:
            return Image(systemName: "clock.fill")
        case .repetitions:
            return Image(systemName: "repeat.circle.fill")
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
                    .overlay(
                        // Tap prompt overlay
                        Group {
                            if showTapPrompt {
                                ZStack {
                                    Color.black.opacity(0.5)
                                    VStack {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                        Text("Tap to view full image")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                    )
            } else {
                ZStack {
                    Color.blue.opacity(0.1)
                    Image(systemName: focusAreaIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
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
                    .background(focusAreaColor)
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
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isAnimatingHeader ? 1.0 : 0.95)
        .opacity(isAnimatingHeader ? 1.0 : 0.8)
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.title)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: {
                        infoType = .duration
                        withAnimation(.spring()) {
                            isShowingInfoOverlay = true
                        }
                    }) {
                        Label("\(exercise.duration) seconds", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        infoType = .repetitions
                        withAnimation(.spring()) {
                            isShowingInfoOverlay = true
                        }
                    }) {
                        Label("\(exercise.repetitions) repetitions", systemImage: "repeat.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Button(action: {
                        infoType = .met
                        withAnimation(.spring()) {
                            isShowingInfoOverlay = true
                        }
                    }) {
                        Label("MET Score: \(String(format: "%.1f", exercise.metScore))", systemImage: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if let user = try? AuthViewModel().user, let weight = user.weight {
                        Spacer()
                        let calories = exercise.caloriesBurned(weight: weight)
                        Label("\(String(format: "%.1f", calories)) calories", systemImage: "bolt.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Instructions")
                    .font(.headline)
                
                Spacer()
                
                // Read aloud controls
                HStack(spacing: 10) {
                    Button(action: {
                        if isPlaying {
                            speechSynthesizer.stopSpeaking(at: .immediate)
                            isPlaying = false
                        } else {
                            readInstructions()
                            isPlaying = true
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isInstructionsExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isInstructionsExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if isInstructionsExpanded || exercise.instructions.count < 200 {
                    Text(exercise.instructions)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 6)
                    
                    if isInstructionsExpanded && exercise.instructions.count >= 200 {
                        Button(action: {
                            withAnimation(.spring()) {
                                isInstructionsExpanded = false
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("Show less")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Image(systemName: "chevron.up")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                } else {
                    Text(exercise.instructions.prefix(200) + "...")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 6)
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isInstructionsExpanded = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Read more")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .animation(.spring(), value: isInstructionsExpanded)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var quoteView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Did You Know?")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
            }
            
            Text(displayedQuote)
                .font(.body)
                .italic()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var knowMoreButton: some View {
        Button(action: {
            let searchTerm = exercise.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "https://www.google.com/search?q=\(searchTerm)+exercise") {
                openURL(url)
            }
        }) {
            HStack {
                Spacer()
                Image(systemName: "magnifyingglass")
                Text("Learn More")
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    .padding(.horizontal)
            )
        }
    }
    
    private var routineButton: some View {
        Button(action: toggleRoutine) {
            HStack {
                Spacer()
                Image(systemName: isInRoutine ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 20))
                Text(isInRoutine ? "Remove from Routine" : "Add to Routine")
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(isInRoutine ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
            .foregroundColor(isInRoutine ? .red : .blue)
            .cornerRadius(10)
            .shadow(color: isInRoutine ? Color.red.opacity(0.1) : Color.blue.opacity(0.1), radius: 3, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.top, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isInRoutine ? Color.red.opacity(0.2) : Color.blue.opacity(0.2), lineWidth: 1)
                    .padding(.horizontal)
                    .padding(.top, 16)
            )
        }
    }
    
    private func fullScreenImageView(_ image: UIImage) -> some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    showingFullImage = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding()
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            
            Spacer()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            
            Spacer()
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var focusAreaIcon: String {
        switch exercise.focusArea {
        case .eye:
            return "eye.fill"
        case .back:
            return "figure.walk"
        case .wrist:
            return "hand.raised.fill"
        }
    }
    
    private var focusAreaColor: Color {
        switch exercise.focusArea {
        case .eye:
            return .blue
        case .back:
            return .green
        case .wrist:
            return .orange
        }
    }
    
    // Helper methods
    private func getRandomQuote() -> String {
        switch exercise.focusArea {
        case .eye:
            return eyeQuotes.randomElement() ?? eyeQuotes[0]
        case .back:
            return backQuotes.randomElement() ?? backQuotes[0]
        case .wrist:
            return wristQuotes.randomElement() ?? wristQuotes[0]
        }
    }
    
    private func getInfoDescription() -> String {
        switch infoType {
        case .met:
            return "Metabolic Equivalent of Task (MET) is a measurement of the energy cost of physical activities. Higher MET scores indicate more intense activities that burn more calories."
        case .duration:
            return "The recommended time to perform this exercise for optimal benefits. Consistency is key - follow the suggested duration for best results."
        case .repetitions:
            return "The number of times you should perform this exercise in a single session. Complete all repetitions to maximize the effectiveness of your break."
        }
    }
    
    // Fixed speech synthesizer function
    private func readInstructions() {
        // Create a new speech synthesizer each time
        let synthesizer = AVSpeechSynthesizer()
        speechSynthesizer = synthesizer
        
        // Create the utterance
        let utterance = AVSpeechUtterance(string: exercise.instructions)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Set up the delegate
        let delegate = SpeechDelegate(isPlaying: $isPlaying)
        speechSynthesizer.delegate = delegate
        
        // Store delegate reference to prevent deallocation
        objc_setAssociatedObject(speechSynthesizer, "delegateReference", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Speak
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
        }
    }
}

// Speech synthesizer delegate to handle speech completion
class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    @Binding var isPlaying: Bool
    
    init(isPlaying: Binding<Bool>) {
        self._isPlaying = isPlaying
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
