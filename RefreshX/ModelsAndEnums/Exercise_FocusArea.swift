// Exercise.swift
import Foundation
import SwiftUI

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let instructions: String
    let thumbnailBase64: String?
    let duration: Int // seconds
    let repetitions: Int
    let focusArea: FocusArea
    let metScore: Double

    var thumbnailImage: UIImage? {
        guard let base64 = thumbnailBase64,
              let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    // Improved caloriesBurned function with better calculation
    func caloriesBurned(weight: Double?) -> Double {
        guard let weight = weight else { return 0 }
        // METs × 3.5 × (weight in kg) / 200 = calories/minute
        let caloriesPerMinute = metScore * 3.5 * (weight / 200)
        // Convert seconds to minutes for calculation
        return caloriesPerMinute * (Double(duration) / 60.0) * Double(repetitions)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case instructions
        case thumbnailBase64 = "thumbnail_base64"
        case duration
        case repetitions
        case focusArea = "focus_area"
        case metScore = "met_score"
    }
}

// FocusArea.swift
import Foundation

enum FocusArea: String, Codable, CaseIterable {
    case eye = "eye"
    case back = "back"
    case wrist = "wrist"
}
