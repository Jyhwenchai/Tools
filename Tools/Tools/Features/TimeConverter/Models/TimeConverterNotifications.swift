//
//  TimeConverterNotifications.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import Foundation

// MARK: - Time Converter Notification Names

extension Notification.Name {
    // Main time converter notifications
    static let timeConverterTriggerConversion = Notification.Name("timeConverterTriggerConversion")
    static let timeConverterTriggerCopy = Notification.Name("timeConverterTriggerCopy")

    // Timestamp to date conversion notifications
    static let timestampToDateTriggerConversion = Notification.Name(
        "timestampToDateTriggerConversion")
    static let timestampToDateTriggerCopy = Notification.Name("timestampToDateTriggerCopy")

    // Date to timestamp conversion notifications
    static let dateToTimestampTriggerConversion = Notification.Name(
        "dateToTimestampTriggerConversion")
    static let dateToTimestampTriggerCopy = Notification.Name("dateToTimestampTriggerCopy")

    // Batch conversion notifications
    static let batchConversionTriggerProcess = Notification.Name("batchConversionTriggerProcess")
    static let batchConversionTriggerCancel = Notification.Name("batchConversionTriggerCancel")

    // Real-time timestamp notifications
    static let realTimeTimestampToggleTimer = Notification.Name("realTimeTimestampToggleTimer")
    static let realTimeTimestampToggleUnit = Notification.Name("realTimeTimestampToggleUnit")
    static let realTimeTimestampCopy = Notification.Name("realTimeTimestampCopy")

    // Background refresh notifications
    static let timeConverterRefreshAfterBackground = Notification.Name(
        "timeConverterRefreshAfterBackground")
}
