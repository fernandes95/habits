//
//  EKEventStore+Swizzle.swift
//  HabitsTests
//
//  Created by Tiago Fernandes on 14/05/2024.
//

import EventKit

extension EKEventStore {
    internal class func swizzle(status: EKAuthorizationStatus = .denied) {
        let mockSelector = if status == .restricted {
            #selector(Self.mockAuthorizationStatusRestricted(for:))
        } else {
            #selector(Self.mockAuthorizationStatusDenied(for:))
        }

        [(#selector(Self.authorizationStatus(for:)), mockSelector)]
            .forEach {
                if let original: Method = class_getClassMethod(self, $0),
                   let mock: Method = class_getClassMethod(self, $1) {
                    method_exchangeImplementations(original, mock)
                }
            }
    }

    internal class func restore(status: EKAuthorizationStatus = .denied) {
        let mockSelector = if status == .restricted {
            #selector(Self.mockAuthorizationStatusRestricted(for:))
        } else {
            #selector(Self.mockAuthorizationStatusDenied(for:))
        }
        
        [(mockSelector, #selector(Self.authorizationStatus(for:)))]
            .forEach {
            if let mock: Method = class_getClassMethod(self, $0),
               let original: Method = class_getClassMethod(self, $1) {
                method_exchangeImplementations(mock, original)
            }
        }
    }

    @objc internal class func mockAuthorizationStatusRestricted(
        for entityType: EKEntityType
    ) -> EKAuthorizationStatus {
        if #available(iOS 17.0, *) {
            .fullAccess
        } else {
            .restricted
        }
    }

    @objc internal class func mockAuthorizationStatusDenied(
        for entityType: EKEntityType
    ) -> EKAuthorizationStatus {
            .denied
    }
}

