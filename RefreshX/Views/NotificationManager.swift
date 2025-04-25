// NotificationManager.swift
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
