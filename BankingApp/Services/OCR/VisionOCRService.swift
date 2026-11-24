import Foundation
import UIKit
import Vision
import ImageIO

public final class VisionOCRService: Sendable {
    /// Performs on-device text recognition on the given image using Apple Vision framework.
    /// - Parameter image: The `UIImage` containing receipt or bank transfer confirmation text
    /// - Returns: Extracted multi-line raw text string
    public static func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = extractCGImage(from: image) else {
            throw NSError(
                domain: "VisionOCRError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage"]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["vi-VN", "en-US"]
            request.usesLanguageCorrection = true

            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func extractCGImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage {
            return cgImage
        }
        if let ciImage = image.ciImage {
            let context = CIContext()
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(image.scale, 1.0)
        let size = image.size.width > 0 && image.size.height > 0 ? image.size : CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let renderedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return renderedImage.cgImage
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
