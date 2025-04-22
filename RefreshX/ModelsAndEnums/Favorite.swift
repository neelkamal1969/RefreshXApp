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
