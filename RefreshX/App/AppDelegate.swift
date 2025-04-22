// AppDelegate.swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set self as the notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // This method will be called when a notification is received while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound])
    }
    
    // This method will be called when a user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle tap on notification
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped with userInfo: \(userInfo)")
        
        // Navigate to Home screen if needed
        // This would require a NotificationCenter post to inform the app
        NotificationCenter.default.post(name: Notification.Name("OpenHomeScreen"), object: nil)
        
        completionHandler()
    }
}
