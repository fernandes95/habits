//
//  EKEventStore+Swizzle.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 14/05/2024.
//

import EventKit

extension EKEventStore {
    internal class func swizzle() {
        [
            (#selector(Self.authorizationStatus(for:)),
             #selector(Self.mockAuthorizationStatus(for:)))
        ].forEach {
            if let original: Method = class_getClassMethod(self, $0),
               let mock: Method = class_getClassMethod(self, $1) {
                method_exchangeImplementations(original, mock)
            }
        }
    }

    internal class func restore() {
        [
            (#selector(Self.mockAuthorizationStatus(for:)),
             #selector(Self.authorizationStatus(for:)))
        ].forEach {
            if let mock: Method = class_getClassMethod(self, $0),
               let original: Method = class_getClassMethod(self, $1) {
                method_exchangeImplementations(mock, original)
            }
        }
    }

    @objc internal class func mockAuthorizationStatus(
        for entityType: EKEntityType
    ) -> EKAuthorizationStatus {
            .denied
    }
}

