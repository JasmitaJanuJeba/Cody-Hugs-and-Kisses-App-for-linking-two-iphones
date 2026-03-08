// QRScannerView.swift
// Camera-based QR code scanner using AVFoundation

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {

    var onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.onScanned = onScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {}

    // MARK: - Scanner view controller

    final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

        var onScanned: ((String) -> Void)?
        private var session: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasScanned = false

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            setupSession()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session?.startRunning()
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session?.stopRunning()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }

        private func setupSession() {
            let session = AVCaptureSession()

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            self.previewLayer = preview

            // Viewfinder overlay
            let overlay = makeOverlay()
            view.addSubview(overlay)

            self.session = session
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = obj.stringValue, !value.isEmpty else { return }
            hasScanned = true
            session?.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onScanned?(value.uppercased())
        }

        private func makeOverlay() -> UIView {
            let container = UIView(frame: view.bounds)
            container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.backgroundColor = .clear

            let size: CGFloat = 220
            let cx = view.bounds.midX - size / 2
            let cy = view.bounds.midY - size / 2
            let cutout = CGRect(x: cx, y: cy, width: size, height: size)

            // Dim overlay with cutout hole
            let dim = UIView(frame: view.bounds)
            dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            dim.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            let mask = CAShapeLayer()
            let path = UIBezierPath(rect: view.bounds)
            path.append(UIBezierPath(roundedRect: cutout, cornerRadius: 12).reversing())
            mask.path = path.cgPath
            dim.layer.mask = mask
            container.addSubview(dim)

            // Corner brackets
            let bracket = UIView(frame: cutout.insetBy(dx: -2, dy: -2))
            bracket.backgroundColor = .clear
            bracket.layer.borderColor = UIColor.systemPink.cgColor
            bracket.layer.borderWidth = 3
            bracket.layer.cornerRadius = 14
            container.addSubview(bracket)

            // Label
            let label = UILabel()
            label.text = "Point at your partner's QR code"
            label.textColor = .white
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textAlignment = .center
            label.frame = CGRect(x: 20, y: cutout.maxY + 20,
                                 width: view.bounds.width - 40, height: 30)
            container.addSubview(label)

            return container
        }
    }
}
