// AppUtilities.swift
import Foundation
import SwiftUI
import AVFoundation

enum ErrorType {
    case network
    case auth
    case data
    case unexpected
    
    var userMessage: String {
        switch self {
        case .network:
            return "Network connection lost. Please check your internet and try again."
        case .auth:
            return "Authentication error. Please sign in again."
        case .data:
            return "Unable to load data. Please try refreshing."
        case .unexpected:
            return "Something went wrong. Please try again."
        }
    }
}

class BMICalculator {
    enum BMICategory: String {
        case underweight = "Underweight"
        case normal = "Normal"
        case overweight = "Overweight"
        case obese = "Obese"
        
        var color: Color {
            switch self {
            case .underweight: return .blue
            case .normal: return .green
            case .overweight: return .orange
            case .obese: return .red
            }
        }
    }
    
    static func calculateBMI(height: Double, weight: Double) -> Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    static func getCategory(bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }
}
struct InfoButton: View {
    let title: String
    let message: String
    
    var body: some View {
        Button(action: {
            let keyWindow = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .first?.windows
                .filter({ $0.isKeyWindow }).first
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            keyWindow?.rootViewController?.present(alertController, animated: true)
        }) {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
        }
    }
}
