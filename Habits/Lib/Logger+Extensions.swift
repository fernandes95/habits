//
//  Logger+Extensions.swift
//  Habits
//
//  Created by Tiago Fernandes on 07/02/2026.
//

import OSLog

extension Logger {
    private static var subsystem  = Bundle.main.bundleIdentifier!

    static let location = Logger(subsystem: subsystem, category: "location")
}
