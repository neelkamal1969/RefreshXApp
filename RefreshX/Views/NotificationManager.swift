////// NotificationManager.swift
////import Foundation
////import UserNotifications
////import SwiftUI
////
////class NotificationManager {
////    static let shared = NotificationManager()
////    
////    private init() {}
////    
////    // Request permission for notifications
////    func requestAuthorization() async -> Bool {
////        do {
////            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
////            return authorized
////        } catch {
////            print("Error requesting notification permission: \(error.localizedDescription)")
////            return false
////        }
////    }
////    
////    // Clear all notifications (for logout)
////    func clearAllNotifications() {
////        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
////        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
////        print("NotificationManager: Cleared all notifications")
////    }
////    
////    // Calculate break times based on user settings
////    func calculateBreakTimes(for user: User) -> [Date] {
////        // Convert job times to Date objects
////        let formatter = DateFormatter()
////        formatter.dateFormat = "HH:mm:ss" // Try HH:mm:ss first (Supabase format)
////        
////        var startDate = formatter.date(from: user.jobStart)
////        var endDate = formatter.date(from: user.jobEnd)
////        
////        // Fallback to HH:mm if HH:mm:ss fails
////        if startDate == nil || endDate == nil {
////            formatter.dateFormat = "HH:mm"
////            startDate = formatter.date(from: user.jobStart)
////            endDate = formatter.date(from: user.jobEnd)
////        }
////        
////        guard let startDate = startDate, let endDate = endDate else {
////            print("Invalid time format for jobStart (\(user.jobStart)) or jobEnd (\(user.jobEnd))")
////            return []
////        }
////        
////        // Convert job times to minutes since midnight
////        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate)
////        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endDate)
////        
////        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
////        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
////        
////        // Handle case where end time is earlier than start (set to default 8-hour workday)
////        let totalWorkMinutes = endMinutes > startMinutes ? endMinutes - startMinutes : 480
////        
////        print("Work hours: \(user.jobStart) to \(user.jobEnd) = \(totalWorkMinutes) minutes")
////        
////        // Calculate interval between breaks
////        let adjustedNumBreaks = max(1, user.numBreaks) // Ensure at least 1 break
////        let breakInterval = totalWorkMinutes / (adjustedNumBreaks + 1)
////        
////        print("Number of breaks: \(adjustedNumBreaks), Break interval: \(breakInterval) minutes")
////        
////        // Calculate break times for today
////        var breakTimes: [Date] = []
////        let today = Calendar.current.startOfDay(for: Date())
////        
////        for i in 1...adjustedNumBreaks {
////            let breakMinutes = startMinutes + (breakInterval * i)
////            let hour = breakMinutes / 60
////            let minute = breakMinutes % 60
////            
////            var components = DateComponents()
////            components.hour = hour
////            components.minute = minute
////            
////            if let breakTime = Calendar.current.date(byAdding: components, to: today) {
////                breakTimes.append(breakTime)
////            }
////        }
////        
////        return breakTimes
////    }
////    
////    // Schedule break notifications based on user settings
////    func scheduleBreakNotifications(for user: User) async {
////        // Clear existing notifications first to avoid duplicates
////        clearAllNotifications()
////        
////        // Check if today is a work day
////        let calendar = Calendar.current
////        let today = calendar.component(.weekday, from: Date())
////        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
////        let todayName = weekdayNames[today - 1] // Adjust for 1-based weekday in Calendar
////        
////        print("NotificationManager: Today is \(todayName)")
////        
////        if !user.weekdays.contains(todayName) {
////            print("NotificationManager: Today (\(todayName)) is not a work day. No notifications scheduled.")
////            return
////        }
////        
////        // Calculate break times for today
////        let breakTimes = calculateBreakTimes(for: user)
////        
////        // Debug: print all calculated break times
////        for (index, breakTime) in breakTimes.enumerated() {
////            let formatter = DateFormatter()
////            formatter.dateFormat = "h:mm a"
////            print("NotificationManager: Break \(index + 1): \(formatter.string(from: breakTime))")
////        }
////        
////        // Check notification authorization
////        let settings = await UNUserNotificationCenter.current().notificationSettings()
////        if settings.authorizationStatus != .authorized {
////            let authorized = await requestAuthorization()
////            if !authorized {
////                print("NotificationManager: Notification permission denied")
////                return
////            }
////        }
////        
////        // Schedule notifications for each break time
////        for (index, breakTime) in breakTimes.enumerated() {
////            // Skip if break time is in the past
////            if breakTime < Date() {
////                print("NotificationManager: Break at \(breakTime) is in the past, skipping notification")
////                continue
////            }
////            
////            // Schedule reminder 5 minutes before
////            let reminderTime = breakTime.addingTimeInterval(-5 * 60)
////            
////            // Skip if reminder time is in the past
////            if reminderTime < Date() {
////                print("NotificationManager: Reminder time for break at \(breakTime) is in the past, skipping notification")
////                continue
////            }
////            
////            // Create notification content
////            let content = UNMutableNotificationContent()
////            content.title = "Break Reminder"
////            content.body = "Your \(user.breakDuration)-minute break starts in 5 minutes!"
////            content.sound = .default
////            
////            // Create trigger based on reminder time
////            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
////            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
////            
////            // Create and add notification request
////            let request = UNNotificationRequest(
////                identifier: "break-reminder-\(index)",
////                content: content,
////                trigger: trigger
////            )
////            
////            do {
////                try await UNUserNotificationCenter.current().add(request)
////                
////                let formatter = DateFormatter()
////                formatter.dateFormat = "h:mm a"
////                print("NotificationManager: ✅ Scheduled notification for break at \(formatter.string(from: breakTime))")
////            } catch {
////                print("NotificationManager: Error scheduling notification: \(error.localizedDescription)")
////            }
////        }
////        
////        // Log the total number of scheduled notifications
////        let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
////        print("NotificationManager: Total pending notifications: \(pendingNotifications.count)")
////    }
////}
//// NotificationManager.swift
//import Foundation
//import UserNotifications
//import SwiftUI
//
//class NotificationManager {
//    static let shared = NotificationManager()
//    
//    private init() {}
//    
//    func requestAuthorization() async -> Bool {
//        do {
//            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
//            return authorized
//        } catch {
//            return false
//        }
//    }
//    
//    func clearAllNotifications() {
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//    }
//    
//    func calculateBreakTimes(for user: User) -> [Date] {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss"
//        var startDate = formatter.date(from: user.jobStart)
//        var endDate = formatter.date(from: user.jobEnd)
//        
//        if startDate == nil || endDate == nil {
//            formatter.dateFormat = "HH:mm"
//            startDate = formatter.date(from: user.jobStart)
//            endDate = formatter.date(from: user.jobEnd)
//        }
//        
//        guard let startDate = startDate, let endDate = endDate else {
//            return []
//        }
//        
//        let calendar = Calendar.current
//        let today = calendar.startOfDay(for: Date())
//        var breakTimes: [Date] = []
//        
//        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
//        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
//        
//        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
//        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
//        
//        var totalWorkMinutes = endMinutes - startMinutes
//        var isOvernight = false
//        
//        if endMinutes <= startMinutes {
//            isOvernight = true
//            totalWorkMinutes = (24 * 60 - startMinutes) + endMinutes
//        }
//        
//        let adjustedNumBreaks = max(1, user.numBreaks)
//        let breakInterval = totalWorkMinutes / (adjustedNumBreaks + 1)
//        
//        for i in 1...adjustedNumBreaks {
//            let breakMinutes = startMinutes + (breakInterval * i)
//            var breakDate = today
//            
//            if isOvernight && breakMinutes >= 24 * 60 {
//                breakDate = calendar.date(byAdding: .day, value: 1, to: today)!
//            }
//            
//            let adjustedBreakMinutes = breakMinutes % (24 * 60)
//            let hour = adjustedBreakMinutes / 60
//            let minute = adjustedBreakMinutes % 60
//            
//            var components = DateComponents()
//            components.hour = hour
//            components.minute = minute
//            
//            if let breakTime = calendar.date(byAdding: components, to: breakDate) {
//                breakTimes.append(breakTime)
//            }
//        }
//        
//        return breakTimes
//    }
//    
//    func scheduleBreakNotifications(for user: User) async {
//        clearAllNotifications()
//        
//        let calendar = Calendar.current
//        let today = calendar.component(.weekday, from: Date())
//        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
//        let todayName = weekdayNames[today - 1]
//        
//        if !user.weekdays.contains(todayName) {
//            return
//        }
//        
//        let breakTimes = calculateBreakTimes(for: user)
//        let settings = await UNUserNotificationCenter.current().notificationSettings()
//        if settings.authorizationStatus != .authorized {
//            let authorized = await requestAuthorization()
//            if !authorized {
//                return
//            }
//        }
//        
//        for (index, breakTime) in breakTimes.enumerated() {
//            if breakTime < Date() {
//                continue
//            }
//            
//            let reminderTime = breakTime.addingTimeInterval(-5 * 60)
//            if reminderTime < Date() {
//                continue
//            }
//            
//            let content = UNMutableNotificationContent()
//            content.title = "Break Reminder"
//            content.body = "Your \(user.breakDuration)-minute break starts in 5 minutes!"
//            content.sound = .default
//            
//            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
//            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
//            
//            let request = UNNotificationRequest(
//                identifier: "break-reminder-\(index)",
//                content: content,
//                trigger: trigger
//            )
//            
//            do {
//                try await UNUserNotificationCenter.current().add(request)
//            } catch {
//                // Silent error handling
//            }
//        }
//    }
//}
import Foundation
import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Requests authorization for notifications
    func requestAuthorization() async -> Bool {
        do {
            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            return authorized
        } catch {
            return false
        }
    }
    
    /// Clears all pending and delivered notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// Calculates break times based on user's work schedule
    func calculateBreakTimes(for user: User) -> [Date] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        var startDate = formatter.date(from: user.jobStart)
        var endDate = formatter.date(from: user.jobEnd)
        
        // Fallback to HH:mm if HH:mm:ss fails
        if startDate == nil || endDate == nil {
            formatter.dateFormat = "HH:mm"
            startDate = formatter.date(from: user.jobStart)
            endDate = formatter.date(from: user.jobEnd)
        }
        
        guard let startDate = startDate, let endDate = endDate else {
            return []
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var breakTimes: [Date] = []
        
        // Convert to minutes since midnight
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle overnight shifts
        var totalWorkMinutes = endMinutes - startMinutes
        var isOvernight = false
        
        if endMinutes <= startMinutes {
            isOvernight = true
            totalWorkMinutes = (24 * 60 - startMinutes) + endMinutes
        }
        
        // Ensure at least one break
        let adjustedNumBreaks = max(1, user.numBreaks)
        let breakInterval = totalWorkMinutes / (adjustedNumBreaks + 1)
        
        for i in 1...adjustedNumBreaks {
            let breakMinutes = startMinutes + (breakInterval * i)
            var breakDate = today
            
            // Adjust for overnight breaks
            if isOvernight && breakMinutes >= 24 * 60 {
                breakDate = calendar.date(byAdding: .day, value: 1, to: today)!
            }
            
            let adjustedBreakMinutes = breakMinutes % (24 * 60)
            let hour = adjustedBreakMinutes / 60
            let minute = adjustedBreakMinutes % 60
            
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            
            if let breakTime = calendar.date(byAdding: components, to: breakDate) {
                breakTimes.append(breakTime)
            }
        }
        
        return breakTimes
    }
    
    /// Schedules break notifications based on user settings
    func scheduleBreakNotifications(for user: User) async {
        // Clear existing notifications to avoid duplicates
        clearAllNotifications()
        
        // Check if today is a work day
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = weekdayNames[today - 1]
        
        if !user.weekdays.contains(todayName) {
            return
        }
        
        // Calculate break times
        let breakTimes = calculateBreakTimes(for: user)
        guard !breakTimes.isEmpty else {
            return
        }
        
        // Check notification authorization
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus != .authorized {
            let authorized = await requestAuthorization()
            if !authorized {
                return
            }
        }
        
        // Schedule notifications
        for (index, breakTime) in breakTimes.enumerated() {
            // Skip past break times
            if breakTime < Date() {
                continue
            }
            
            // Schedule 5-minute reminder
            let reminderTime = breakTime.addingTimeInterval(-5 * 60)
            if reminderTime < Date() {
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Break Reminder"
            content.body = "Your \(user.breakDuration)-minute break starts in 5 minutes!"
            content.sound = .default
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "break-reminder-\(index)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                // Silent error handling in production
            }
        }
    }
}
