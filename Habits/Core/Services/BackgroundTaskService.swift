//
//  BackgroundTaskService.swift
//  Habits
//
//  Created by Tiago Fernandes on 24/03/2024.
//

import Foundation
import BackgroundTasks

struct BackgroundTaskService {
    private let taskScheduler: BGTaskScheduler = BGTaskScheduler.shared

    func registerBackgroundTask(identifier: String, launchHandler: @escaping (BGTask) -> Void) {
        taskScheduler.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            launchHandler(task)
        }
    }

    func requestRefreshTask(identifier: String) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .second, value: 30, to: Date.now)

       do {
          try taskScheduler.submit(request)
       } catch let error {
           print("Background Refresh Task Schedule error: \(error.localizedDescription)")
       }
    }
}
