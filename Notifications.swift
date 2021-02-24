//
//  Notifications.swift
//  Zoom
//
//  Created by Benjamin Who on 2/20/21.
//

import Foundation
import SwiftUI
import CoreData

class LocalNotificationManager: ObservableObject {
    
    @Environment(\.managedObjectContext) private var viewContext

    
    var meetings: Item?
    
    var notifications = [Notification]()
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                print("Notifications permitted")
            } else {
                print("Notifications not permitted")
            }
        }
        
    }
    func sendNotification(title: String, subtitle: String?, body: String, time: Date, meetingName: String) {
            
            let content = UNMutableNotificationContent()
            content.title = title
            if let subtitle = subtitle {
                content.subtitle = subtitle
            }
            content.body = body
               
            let triggerDate = time - 5 * 60
                let trigger = UNCalendarNotificationTrigger(
                            dateMatching: Calendar.current.dateComponents([.timeZone, .year, .month, .day, .hour, .minute], from: triggerDate),
                            repeats: true
                )
            
        let request = UNNotificationRequest(identifier: "\(meetingName)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
            
        }
    
    func removePendingNotificationRequests(meetingID: String?) {
        removePendingNotificationRequests(meetingID: meetingID)
        return
    }
    

}
