// PairingService.swift
// Manages the pairing flow: create invite → generate QR → listen for acceptance
//             OR: scan QR → accept invite → notify inviter

import SwiftUI
import CoreImage.CIFilterBuiltins

@MainActor
public final class PairingService: ObservableObject {

    @Published public var state: PairingState = .idle
    @Published public var errorMessage: String? = nil
    @Published public var inviteCode: String = ""
    @Published public var qrImage: UIImage? = nil

    private var pollingTask: Task<Void, Never>? = nil

    public enum PairingState {
        case idle
        case creatingInvite
        case waitingForPartner       // inviter side
        case enteringCode            // joiner side
        case joining
        case paired
    }

    // MARK: - Inviter flow

    public func startInvite(appState: AppState) {
        state = .creatingInvite
        errorMessage = nil

        Task {
            do {
                let uid = try await FirebaseService.shared.signInAnonymously()
                appState.myUID = uid
                SharedDefaults.set(uid, for: .myUID)

                let code = try await FirebaseService.shared.createInvite(
                    uid: uid,
                    name: appState.myName,
                    fcmToken: appState.fcmToken
                )
                self.inviteCode = code
                self.qrImage    = generateQR(from: code)
                self.state      = .waitingForPartner

                // Poll for partner acceptance
                let (partnerUID, partnerName) = try await FirebaseService.shared.waitForAcceptance(code: code)
                appState.completePairing(partnerUID: partnerUID, partnerName: partnerName)
                self.state = .paired

            } catch {
                self.state = .idle
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Joiner flow

    public func joinWithCode(_ code: String, appState: AppState) {
        state = .joining
        errorMessage = nil

        Task {
            do {
                let uid = try await FirebaseService.shared.signInAnonymously()
                appState.myUID = uid
                SharedDefaults.set(uid, for: .myUID)

                let (partnerUID, partnerName) = try await FirebaseService.shared.acceptInvite(
                    code: code.uppercased(),
                    accepterUID: uid,
                    accepterName: appState.myName,
                    accepterFCMToken: appState.fcmToken
                )
                appState.completePairing(partnerUID: partnerUID, partnerName: partnerName)
                self.state = .paired

            } catch {
                self.state = .idle
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - QR Code

    private func generateQR(from string: String) -> UIImage? {
        let context  = CIContext()
        let filter   = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        // Tint to pink
        let size = CGSize(width: scaled.extent.width, height: scaled.extent.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage(cgImage: cgImage) }

        ctx.setFillColor(UIColor.systemPink.withAlphaComponent(0.15).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size),
                                       blendMode: .multiply,
                                       alpha: 1.0)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Cancel

    public func cancel() {
        pollingTask?.cancel()
        state = .idle
    }
}
