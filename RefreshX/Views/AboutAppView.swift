// AppViews.swift
import SwiftUI
import Combine
import AVFAudio


// MARK: - Read Aloud Manager (Fixed Memory Issues)
class ReadAloudManager: NSObject, ObservableObject {
    static let shared = ReadAloudManager()
    
    @Published var isPlaying: Bool = false
    @Published var currentText: String = ""
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupAudioSession()
        speechSynthesizer.delegate = self
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
                .sink { [weak self] notification in
                    self?.handleInterruption(notification: notification)
                }
                .store(in: &cancellables)
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
        }
    }
    
    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            stop()
        }
    }
    
    func speak(text: String) {
        guard !text.isEmpty else { return }
        
        if isPlaying {
            stop()
        }
        
        currentText = text
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = true
            self?.speechSynthesizer.speak(utterance)
        }
    }
    
    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

extension ReadAloudManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
    }
}


// MARK: - Shared UI Components
struct AppSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(color)
                )
                .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.bottom, 10)
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 6)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                Image(systemName: icon)
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 3)
            )
            .padding(.horizontal)
        }
    }
}

struct ContactInfoCard: View {
    let name: String
    let email: String
    let phone: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contact Information")
                .font(.headline)
                .padding(.bottom, 4)
            
            InfoItem(label: "Name", value: name)
            InfoItem(label: "Email", value: email)
            InfoItem(label: "Phone", value: phone)
            
            Text("We value your feedback and are constantly working to improve RefreshX.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - About App View (Refined)
struct AboutAppView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var readAloudManager = ReadAloudManager.shared
    @State private var animateIcon = false
    
    private let aboutText = """
    RefreshX is your personal break-time assistant designed to help you maintain a healthy work routine. In today's digital world, extended screen time can lead to various health issues, including eye strain, back pain, and wrist problems.
    
    Key Features:
    
    • Smart Break Scheduling
    • Targeted Exercises
    • Progress Tracking
    • Health Articles
    
    We're committed to helping you stay healthy during your workday.
    """
    
    private let socialLinks = [
        (icon: "envelope.fill", color: Color.blue, url: "mailto:heeyyyprince@gmail.com"),
        (icon: "globe", color: Color.green, url: "https://refresh-x-app-29lb.vercel.app"),
        (icon: "link.circle.fill", color: Color.purple, url: "https://github.com/heeyyyprince")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 110, height: 110)
                    
                    Image("appImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .rotation3DEffect(
                            .degrees(animateIcon ? 3 : -3),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
                .padding(.top, 20)
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateIcon = true
                    }
                }
                
                // Title
                Text("About RefreshX")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                // Main content
                VStack(alignment: .leading, spacing: 16) {
                    Text(aboutText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 16)
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Information")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Group {
                        InfoItem(label: "Version", value: "1.0")
                        InfoItem(label: "Build", value: "2023.04.001")
                        InfoItem(label: "Developer", value: "Prince Kumar")
                        InfoItem(label: "Platform", value: "iOS 15+")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
                )
                .padding(.horizontal)
                
                // Social links
                VStack(spacing: 16) {
                    Text("Connect With Us")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(socialLinks, id: \.icon) { link in
                            SocialButton(icon: link.icon, color: link.color, url: link.url)
                        }
                    }
                }
                .padding(.top, 16)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleReadAloud) {
                    Image(systemName: readAloudManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            readAloudManager.stop()
        }
    }
    
    private func toggleReadAloud() {
        if readAloudManager.isPlaying {
            readAloudManager.stop()
        } else {
            readAloudManager.speak(text: aboutText)
        }
    }
}

private struct SocialButton: View {
    let icon: String
    let color: Color
    let url: String
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                openURL(url)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                )
        }
    }
}

// MARK: - Support View (Refined)
struct SupportView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @StateObject private var readAloudManager = ReadAloudManager.shared
    @State private var expandedQuestion: String?
    
    private let supportText = """
    We're here to help you get the most out of RefreshX. If you're experiencing any issues or have questions about how to use the app, we're here to assist you.
    """
    
    private let faqItems = [
        ("How are breaks scheduled?", "Breaks are spaced evenly throughout your workday based on your start and end times."),
        ("Why enter height and weight?", "This helps calculate calories burned during exercises more accurately."),
        ("Can I customize exercises?", "Yes! Visit the Exercises tab to browse and add exercises."),
        ("How to change notifications?", "Adjust your break schedule in Profile settings."),
        ("Is my data secure?", "Yes, your information is securely stored and never shared.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AppSectionHeader(
                    title: "Support",
                    icon: "questionmark.circle.fill",
                    color: .blue
                )
                .padding(.top, 20)
                
                Text(supportText)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // FAQ Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frequently Asked Questions")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 0) {
                        ForEach(faqItems, id: \.0) { item in
                            FAQItem(
                                question: item.0,
                                answer: item.1,
                                isExpanded: expandedQuestion == item.0,
                                action: {
                                    withAnimation(.spring()) {
                                        expandedQuestion = expandedQuestion == item.0 ? nil : item.0
                                    }
                                }
                            )
                            
                            if item.0 != faqItems.last?.0 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
                    )
                }
                .padding(.horizontal)
                
                ContactInfoCard(
                    name: "Prince Kumar",
                    email: "heeyyyprince@gmail.com",
                    phone: "+91 7527017902"
                )
                .padding(.horizontal)
                
                ActionButton(
                    title: "Contact Support",
                    icon: "arrow.right",
                    action: {
                        if let url = URL(string: "https://refresh-x-app-29lb.vercel.app") {
                            openURL(url)
                        }
                    },
                    color: .blue
                )
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleReadAloud) {
                    Image(systemName: readAloudManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            readAloudManager.stop()
        }
    }
    
    private func toggleReadAloud() {
        if readAloudManager.isPlaying {
            readAloudManager.stop()
        } else {
            readAloudManager.speak(text: supportText + "\n\n" + faqItems.map { "\($0.0): \($0.1)" }.joined(separator: "\n\n"))
        }
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Privacy Policy View (Refined)
struct PrivacyPolicyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @StateObject private var readAloudManager = ReadAloudManager.shared
    @State private var expandedSection: String?
    
    private let privacyText = """
    At RefreshX, we take your privacy seriously. This Privacy Policy describes how we collect, use, and handle your personal information when you use our application.
    """
    
    private let privacySections = [
        ("Information We Collect", [
            "• Personal Information: Name, email address",
            "• Physical Information: Height, weight",
            "• Usage Information: Break schedules",
            "• Device Information: Device model, OS"
        ]),
        ("How We Use Information", [
            "• Provide personalized break reminders",
            "• Calculate calories burned",
            "• Improve application experience",
            "• Send relevant notifications"
        ]),
        ("Data Security", [
            "We implement appropriate security measures to protect your personal information against unauthorized access."
        ]),
        ("Your Rights", [
            "You can access, update, or delete your account information at any time through the app settings."
        ])
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AppSectionHeader(
                    title: "Privacy Policy",
                    icon: "lock.shield.fill",
                    color: .blue
                )
                .padding(.top, 20)
                
                Text(privacyText)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Privacy sections
                VStack(spacing: 12) {
                    ForEach(privacySections, id: \.0) { section in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedSection == section.0 },
                                set: { _ in
                                    withAnimation {
                                        expandedSection = expandedSection == section.0 ? nil : section.0
                                    }
                                }
                            ),
                            content: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(section.1, id: \.self) { item in
                                        Text(item)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 8)
                            },
                            label: {
                                Text(section.0)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
                        )
                    }
                }
                .padding(.horizontal)
                
                ContactInfoCard(
                    name: "Prince Kumar",
                    email: "heeyyyprince@gmail.com",
                    phone: "+91 7527017902"
                )
                .padding(.horizontal)
                
                ActionButton(
                    title: "View Full Policy",
                    icon: "doc.text",
                    action: {
                        if let url = URL(string: "https://refresh-x-app-dk36.vercel.app") {
                            openURL(url)
                        }
                    },
                    color: .blue
                )
                
                Text("Last Updated: April 2023")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleReadAloud) {
                    Image(systemName: readAloudManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            readAloudManager.stop()
        }
    }
    
    private func toggleReadAloud() {
        if readAloudManager.isPlaying {
            readAloudManager.stop()
        } else {
            let fullText = privacyText + "\n\n" + privacySections.map { section in
                section.0 + "\n" + section.1.joined(separator: "\n")
            }.joined(separator: "\n\n")
            readAloudManager.speak(text: fullText)
        }
    }
}
