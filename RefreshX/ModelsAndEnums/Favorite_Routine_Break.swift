// Favorite.swift
import Foundation

struct Favorite: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let articleId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case articleId = "article_id"
    }
}


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

// Break.swift
import Foundation

struct Break: Identifiable, Codable ,Equatable{
    let id: UUID
    let userId: UUID
    let scheduledTime: Date
    let completed: Bool
    let exerciseId: UUID?

    // Computed property to check if break is active
    var isActive: Bool {
        let now = Date()
        let endTime = scheduledTime.addingTimeInterval(TimeInterval(60))
        return !completed && now >= scheduledTime && now <= endTime
    }

    init(id: UUID = UUID(), userId: UUID, scheduledTime: Date, completed: Bool = false, exerciseId: UUID? = nil) {
        self.id = id
        self.userId = userId
        self.scheduledTime = scheduledTime
        self.completed = completed
        self.exerciseId = exerciseId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scheduledTime = "scheduled_time"
        case completed
        case exerciseId = "exercise_id"
    }
}



