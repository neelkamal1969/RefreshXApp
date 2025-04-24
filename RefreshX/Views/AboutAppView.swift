// some AppViews.swift
//AboutAppView.swift
import SwiftUI

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var readAloudManager = ReadAloudManager.shared
    
    let aboutText = """
    About RefreshX

    RefreshX is your personal break-time assistant designed to help you maintain a healthy work routine. In today's digital world, extended screen time can lead to various health issues, including eye strain, back pain, and wrist problems. RefreshX helps you combat these issues by reminding you to take regular breaks and guiding you through quick exercises.

    Key Features:

    • Smart Break Scheduling: Customized break reminders based on your work hours
    • Targeted Exercises: Quick and effective exercises for eyes, back, and wrists
    • Progress Tracking: Monitor your break streak and calories burned
    • Health Articles: Informative articles about workplace wellness

    Version: 1.0
    Released: April 2023
    Developer: Prince Kumar

    Thank you for using RefreshX. We're committed to helping you stay healthy during your workday.
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Image("appImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                    Spacer()
                }
                .padding()
                
                Text("About RefreshX")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(aboutText)
                    .padding(.horizontal)
                
                Divider()
                    .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2023.04.001")
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Prince Kumar")
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if readAloudManager.isPlaying {
                        readAloudManager.stop()
                    } else {
                        readAloudManager.speak(text: aboutText)
                    }
                }) {
                    Image(systemName: readAloudManager.isPlaying ? "pause.circle" : "play.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            readAloudManager.stop()
        }
    }
}

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var readAloudManager = ReadAloudManager.shared
    
    let supportText = """
    Support for RefreshX

    We're here to help you get the most out of RefreshX. If you're experiencing any issues or have questions about how to use the app, we're here to assist you.

    Common Questions:

    • How are breaks scheduled?
      Breaks are spaced evenly throughout your workday based on your start and end times. You'll receive a notification 5 minutes before each break.

    • Why do I need to enter my height and weight?
      This information helps us calculate calories burned during exercises more accurately.

    • Can I customize my exercise routine?
      Yes! Visit the Exercises tab to browse available exercises and add them to your routine.

    • How do I change my notification settings?
      You can adjust your break schedule in your Profile settings.

    If you need additional help, please don't hesitate to reach out to our support team.
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding()
                
                Text("Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(supportText)
                    .padding(.horizontal)
                
                Divider()
                    .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Information")
                        .font(.headline)
                    Text("Name: Prince Kumar")
                    Text("Email: heeyyyprince@gmail.com")
                    Text("Phone: +91 7527017902")
                    Text("We value your feedback and are constantly working to improve RefreshX.")
                        .padding(.top, 8)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Link(destination: URL(string: "https://refresh-x-app-29lb.vercel.app")!) {
                    HStack {
                        Text("Contact Support")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
                }
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if readAloudManager.isPlaying {
                        readAloudManager.stop()
                    } else {
                        readAloudManager.speak(text: supportText)
                    }
                }) {
                    Image(systemName: readAloudManager.isPlaying ? "pause.circle" : "play.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            readAloudManager.stop()
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var readAloudManager = ReadAloudManager.shared
    
    let privacyText = """
    Privacy Policy for RefreshX

    At RefreshX, we take your privacy seriously. This Privacy Policy describes how we collect, use, and handle your personal information when you use our application.

    Information We Collect:
    • Personal Information: Name, email address
    • Physical Information: Height, weight (for calorie calculations)
    • Usage Information: Break schedules, exercise routines
    • Device Information: Device model, operating system

    How We Use Your Information:
    • To provide personalized break reminders
    • To calculate calories burned during exercises
    • To improve our application and user experience
    • To send notifications related to your break schedule

    Data Security:
    We implement appropriate security measures to protect your personal information against unauthorized access or disclosure.

    Your Rights:
    You can access, update, or delete your account information at any time through the app settings.

    Contact Us:
    If you have any questions or concerns about this Privacy Policy, please contact us.
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding()
                
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(privacyText)
                    .padding(.horizontal)
                
                Divider()
                    .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Information")
                        .font(.headline)
                    Text("Name: Prince Kumar")
                    Text("Email: heeyyyprince@gmail.com")
                    Text("Phone: +91 7527017902")
                }
                .padding(.horizontal)
                
                Link(destination: URL(string: "https://refresh-x-app-dk36.vercel.app")!) {
                    HStack {
                        Text("Know More")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
                }
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if readAloudManager.isPlaying {
                        readAloudManager.stop()
                    } else {
                        readAloudManager.speak(text: privacyText)
                    }
                }) {
                    Image(systemName: readAloudManager.isPlaying ? "pause.circle" : "play.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onDisappear {
            readAloudManager.stop()
        }
    }
}
