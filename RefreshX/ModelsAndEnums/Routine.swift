// Routine.swift
import Foundation

struct Routine: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let exerciseId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case exerciseId = "exercise_id"
    }
}
