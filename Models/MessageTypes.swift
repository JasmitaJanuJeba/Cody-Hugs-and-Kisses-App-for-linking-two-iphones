// MessageTypes.swift
// Firestore document shapes and notification payload keys

import Foundation

// MARK: - Firestore document written when a hug/kiss is sent

public struct HugKissMessage: Codable {
    public var type: String          // "hug" | "kiss"
    public var senderUID: String
    public var recipientUID: String
    public var duration: Double      // seconds the recipient should vibrate
    public var intensity: Double     // 0.0 – 1.0
    public var pattern: String       // HapticPattern.rawValue
    public var sentAt: Date
    public var consumed: Bool        // set to true once recipient processes it

    public init(type: String,
                senderUID: String,
                recipientUID: String,
                duration: Double,
                intensity: Double,
                pattern: HapticPattern,
                sentAt: Date = Date()) {
        self.type = type
        self.senderUID = senderUID
        self.recipientUID = recipientUID
        self.duration = duration
        self.intensity = intensity
        self.pattern = pattern.rawValue
        self.sentAt = sentAt
        self.consumed = false
    }
}

// MARK: - FCM push notification payload keys

public enum PushKey {
    static let type       = "hk_type"       // "hug" | "kiss"
    static let duration   = "hk_duration"
    static let intensity  = "hk_intensity"
    static let pattern    = "hk_pattern"
    static let senderName = "hk_sender"
}

// MARK: - Pairing invite document stored in Firestore

public struct PairingInvite: Codable {
    public var inviterUID: String
    public var inviterName: String
    public var inviterFCMToken: String
    public var createdAt: Date
    public var accepted: Bool

    public init(inviterUID: String, inviterName: String, inviterFCMToken: String) {
        self.inviterUID = inviterUID
        self.inviterName = inviterName
        self.inviterFCMToken = inviterFCMToken
        self.createdAt = Date()
        self.accepted = false
    }
}
