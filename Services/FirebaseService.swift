// FirebaseService.swift
// Handles Firestore reads/writes and FCM push notification dispatch.
//
// Firestore structure:
//   users/{uid}           – profile + FCM token
//   invites/{inviteCode}  – pairing invite
//   messages/{msgId}      – incoming hug/kiss commands

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

public final class FirebaseService {

    public static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private var messageListener: ListenerRegistration?

    private init() {}

    // MARK: - Auth (anonymous)

    /// Signs in anonymously if needed; returns the UID.
    public func signInAnonymously() async throws -> String {
        if let uid = Auth.auth().currentUser?.uid { return uid }
        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }

    // MARK: - User profile

    /// Saves display name + FCM token to Firestore.
    public func createProfile(uid: String, name: String, fcmToken: String) async throws {
        try await db.collection("users").document(uid).setData([
            "name": name,
            "fcmToken": fcmToken,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    /// Updates just the FCM token (called on token refresh).
    public func updateFCMToken(_ token: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid)
            .setData(["fcmToken": token], merge: true)
    }

    // MARK: - Pairing

    /// Creates an invite document; returns the 6-char invite code.
    public func createInvite(uid: String, name: String, fcmToken: String) async throws -> String {
        let code = randomCode()
        let invite = PairingInvite(inviterUID: uid, inviterName: name, inviterFCMToken: fcmToken)
        try await db.collection("invites").document(code).setData(from: invite)
        return code
    }

    /// Fetches the invite for `code` and writes the accepter's info.
    /// Returns (inviterUID, inviterName).
    public func acceptInvite(code: String,
                             accepterUID: String,
                             accepterName: String,
                             accepterFCMToken: String) async throws -> (String, String) {
        let ref = db.collection("invites").document(code)
        let snap = try await ref.getDocument()
        guard snap.exists,
              let invite = try? snap.data(as: PairingInvite.self),
              !invite.accepted
        else { throw PairingError.invalidCode }

        // Mark accepted + store accepter info so inviter can read it
        try await ref.setData([
            "accepted": true,
            "accepterUID": accepterUID,
            "accepterName": accepterName,
            "accepterFCMToken": accepterFCMToken
        ], merge: true)

        return (invite.inviterUID, invite.inviterName)
    }

    /// Polls the invite document waiting for acceptance (inviter's side).
    public func waitForAcceptance(code: String) async throws -> (String, String) {
        for _ in 0..<30 {                          // poll up to ~60 s
            let snap = try await db.collection("invites").document(code).getDocument()
            if let accepted = snap.data()?["accepted"] as? Bool, accepted,
               let uid  = snap.data()?["accepterUID"]  as? String,
               let name = snap.data()?["accepterName"] as? String {
                return (uid, name)
            }
            try await Task.sleep(nanoseconds: 2_000_000_000)   // 2 s
        }
        throw PairingError.timeout
    }

    // MARK: - Send hug / kiss

    /// Writes a message to Firestore and triggers a Cloud Function that
    /// sends the FCM push to the recipient.
    public func send(type: String,
                     senderUID: String,
                     senderName: String,
                     recipientUID: String,
                     settings: UserHapticSettings) async throws {

        let duration  = type == "hug" ? settings.hugDuration  : settings.kissDuration
        let intensity = type == "hug" ? settings.hugIntensity : settings.kissIntensity
        let pattern   = type == "hug" ? settings.hugPattern   : settings.kissPattern

        // 1. Fetch recipient's FCM token
        let recipientDoc = try await db.collection("users").document(recipientUID).getDocument()
        guard let fcmToken = recipientDoc.data()?["fcmToken"] as? String else {
            throw SendError.noToken
        }

        // 2. Write message record
        let msg = HugKissMessage(type: type,
                                 senderUID: senderUID,
                                 recipientUID: recipientUID,
                                 duration: duration,
                                 intensity: intensity,
                                 pattern: pattern)
        _ = try db.collection("messages").addDocument(from: msg)

        // 3. Call Cloud Function to send FCM (keeps service account key server-side)
        let functions = Functions.functions()
        try await functions.httpsCallable("sendHugKiss").call([
            "recipientToken": fcmToken,
            "type":           type,
            "duration":       String(duration),
            "intensity":      String(intensity),
            "pattern":        pattern.rawValue,
            "senderName":     senderName
        ])
    }

    // MARK: - Incoming message listener

    /// Listens for unconsumed messages addressed to `myUID`.
    public func listenForMessages(myUID: String,
                                  onReceive: @escaping (HugKissMessage, String) -> Void) {
        messageListener?.remove()
        messageListener = db.collection("messages")
            .whereField("recipientUID", isEqualTo: myUID)
            .whereField("consumed", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documentChanges.filter({ $0.type == .added })
                else { return }
                for change in docs {
                    if var msg = try? change.document.data(as: HugKissMessage.self) {
                        let docID = change.document.documentID
                        onReceive(msg, docID)
                        // Mark consumed
                        self.db.collection("messages").document(docID)
                            .updateData(["consumed": true])
                    }
                }
            }
    }

    public func removeListeners() {
        messageListener?.remove()
    }

    // MARK: - Helpers

    private func randomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Errors

public enum PairingError: LocalizedError {
    case invalidCode, timeout
    public var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid or expired invite code."
        case .timeout:     return "Timed out waiting for partner to join."
        }
    }
}

public enum SendError: LocalizedError {
    case noToken
    public var errorDescription: String? { "Partner's device token not found." }
}
