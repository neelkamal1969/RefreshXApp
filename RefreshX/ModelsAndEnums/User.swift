//User.swift
import Foundation

struct User: Identifiable, Codable,Equatable{
    let id: UUID
    var name: String
    let email: String
    var height: Double?
    var weight: Double?
    var bio: String?
    var weekdays: [String]
    var jobStart: String // Kept as String, validated as "HH:mm"
    var jobEnd: String   // Kept as String, validated as "HH:mm"
    var numBreaks: Int
    var breakDuration: Int
    
    // Validate HH:mm format for jobStart and jobEnd
    func isValidTimeFormat(_ time: String) -> Bool {
        let regex = "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$"
        return time.range(of: regex, options: .regularExpression) != nil
    }
    
    // Add a convenient initializer with defaults
    init(id: UUID, name: String = "User", email: String,
         height: Double? = nil, weight: Double? = nil, bio: String? = nil,
         weekdays: [String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
         jobStart: String = "06:00", jobEnd: String = "21:00",
         numBreaks: Int = 5, breakDuration: Int = 20) {
        self.id = id
        self.name = name
        self.email = email
        self.height = height
        self.weight = weight
        self.bio = bio
        self.weekdays = weekdays
        self.jobStart = jobStart
        self.jobEnd = jobEnd
        self.numBreaks = numBreaks
        self.breakDuration = breakDuration
        
        // Validate time format
        if !isValidTimeFormat(jobStart) || !isValidTimeFormat(jobEnd) {
            print("Warning: Invalid time format for jobStart (\(jobStart)) or jobEnd (\(jobEnd))")
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case height
        case weight
        case bio
        case weekdays
        case jobStart = "job_start"
        case jobEnd = "job_end"
        case numBreaks = "num_breaks"
        case breakDuration = "break_duration"
    }
}
