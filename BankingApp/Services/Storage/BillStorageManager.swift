import Foundation
import UIKit

public final class BillStorageManager: Sendable {
    public static let shared = BillStorageManager()
    private let baseDirectory: URL

    public init(baseDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory) {
        self.baseDirectory = baseDirectory
    }

    /// Saves a bill image compressed as JPEG into App Sandbox under `Documents/Bills/YYYY-MM/`
    /// - Parameter image: The bill screenshot to save
    /// - Returns: The relative path to the saved image (e.g. `Bills/2026-11/bill_<uuid>.jpg`)
    @discardableResult
    public func saveBillImage(_ image: UIImage) throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM"
        let folderName = dateFormatter.string(from: Date())
        
        let folderURL = baseDirectory.appendingPathComponent("Bills").appendingPathComponent(folderName)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        let fileName = "bill_\(UUID().uuidString).jpg"
        let fileURL = folderURL.appendingPathComponent(fileName)

        var imageData = image.jpegData(compressionQuality: 0.8)
        if imageData == nil {
            let format = UIGraphicsImageRendererFormat()
            format.scale = max(image.scale, 1.0)
            let size = image.size.width > 0 && image.size.height > 0 ? image.size : CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let rasterized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            imageData = rasterized.jpegData(compressionQuality: 0.8)
        }

        guard let data = imageData else {
            throw NSError(
                domain: "BillStorageError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]
            )
        }

        try data.write(to: fileURL)
        return "Bills/\(folderName)/\(fileName)"
    }

    /// Loads a bill image from the relative path within the base directory
    /// - Parameter relativePath: The relative path stored with the transaction
    /// - Returns: The loaded `UIImage`, or `nil` if not found or path is invalid
    public func loadBillImage(relativePath: String) -> UIImage? {
        guard !relativePath.contains("..") else { return nil }
        let cleanPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fileURL = baseDirectory.appendingPathComponent(cleanPath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Deletes a bill image at the specified relative path
    /// - Parameter relativePath: The relative path stored with the transaction
    public func deleteBillImage(relativePath: String) {
        guard !relativePath.contains("..") else { return }
        let cleanPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fileURL = baseDirectory.appendingPathComponent(cleanPath)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
