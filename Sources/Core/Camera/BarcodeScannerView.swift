import AVFoundation
import SwiftUI

struct BarcodeScannerView: UIViewRepresentable {
    var onBarcode: (String) -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        view.configure(delegate: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcode: onBarcode)
    }

    // MARK: – Preview UIView

    final class ScannerPreviewView: UIView {
        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        func configure(delegate: AVCaptureMetadataOutputObjectsDelegate) {
            guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else { return }

            session.beginConfiguration()

            guard
                let device = AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input)
            else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(delegate, queue: .main)
            output.metadataObjectTypes = [
                .ean13, .ean8, .qr, .code128, .code39, .code93,
                .upce, .aztec, .dataMatrix, .pdf417, .itf14
            ]

            session.commitConfiguration()

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            self.layer.addSublayer(preview)
            self.previewLayer = preview

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }

        func stop() {
            session.stopRunning()
        }

        func start() {
            guard !session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    // MARK: – Coordinator

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onBarcode: (String) -> Void
        private var lastCode: String?
        private var lastTime: Date = .distantPast

        init(onBarcode: @escaping (String) -> Void) {
            self.onBarcode = onBarcode
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let code = object.stringValue
            else { return }

            // Debounce — ignore same code within 2 seconds
            let now = Date()
            if code == lastCode, now.timeIntervalSince(lastTime) < 2 { return }
            lastCode = code
            lastTime = now

            onBarcode(code)
        }
    }
}
