// Article.swift
import Foundation
import SwiftUI

struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: String
    let thumbnailBase64: String?
    let dateAdded: Date
    let type: FocusArea
    let content: String

    var thumbnailImage: UIImage? {
        guard let base64 = thumbnailBase64,
              let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case thumbnailBase64 = "thumbnail_base64"
        case dateAdded = "date_added"
        case type
        case content
    }
}


// ReadArticle.swift
import Foundation

struct ReadArticle: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let articleId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case articleId = "article_id"
    }
}
