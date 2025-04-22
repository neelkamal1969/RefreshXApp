// AppError.swift
import Foundation

enum AppError: LocalizedError {
    case authError(String)
    case networkError(String)
    case dataError(String)
    case unexpectedError(String)
    
    var errorDescription: String? {
        switch self {
        case .authError(let message):
            return "Authentication Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .unexpectedError(let message):
            return "Unexpected Error: \(message)"
        }
    }
}
