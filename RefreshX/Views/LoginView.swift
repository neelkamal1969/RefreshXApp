// LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var otp = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("RefreshX")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("Your break time assistant")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 30)
            
            // Form
            if authViewModel.isOTPMode {
                TextField("Enter OTP", text: $otp)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                
                Button("Verify OTP") {
                    Task {
                        await authViewModel.verifyOTP(email: email, token: otp)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(authViewModel.isLoading || otp.isEmpty)
                
                Button("Back") {
                    authViewModel.isOTPMode = false
                    authViewModel.errorMessage = nil
                    otp = ""
                }
                .foregroundColor(.blue)
                .disabled(authViewModel.isLoading)
            } else {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                Button("Send OTP") {
                    Task {
                        await authViewModel.sendOTP(email: email)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(authViewModel.isLoading || email.isEmpty)
            }
            
            // Feedback
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if authViewModel.isLoading {
                ProgressView()
            }
            
            Spacer()
        }
        .padding()
        .navigationBarHidden(true)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
