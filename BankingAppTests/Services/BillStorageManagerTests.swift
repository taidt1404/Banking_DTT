import XCTest
import UIKit
@testable import BankingDTT

final class BillStorageManagerTests: XCTestCase {
    func testSaveAndRetrieveBillImage() throws {
        let storage = BillStorageManager(baseDirectory: FileManager.default.temporaryDirectory)
        let sampleImage = UIImage(systemName: "checkmark.seal.fill") ?? UIImage()
        
        let relativePath = try storage.saveBillImage(sampleImage)
        XCTAssertFalse(relativePath.isEmpty)
        XCTAssertTrue(relativePath.hasPrefix("Bills/"))
        
        let loaded = storage.loadBillImage(relativePath: relativePath)
        XCTAssertNotNil(loaded)
        
        storage.deleteBillImage(relativePath: relativePath)
        XCTAssertNil(storage.loadBillImage(relativePath: relativePath))
    }

    func testLoadNonExistentImageReturnsNil() {
        let storage = BillStorageManager(baseDirectory: FileManager.default.temporaryDirectory)
        let result = storage.loadBillImage(relativePath: "Bills/2026-11/non_existent.jpg")
        XCTAssertNil(result)
    }

    func testDeleteNonExistentImageDoesNotCrash() {
        let storage = BillStorageManager(baseDirectory: FileManager.default.temporaryDirectory)
        storage.deleteBillImage(relativePath: "Bills/2026-11/non_existent.jpg")
    }

    func testDirectoryTraversalPrevention() {
        let storage = BillStorageManager(baseDirectory: FileManager.default.temporaryDirectory)
        let result = storage.loadBillImage(relativePath: "../../etc/passwd")
        XCTAssertNil(result)
        
        storage.deleteBillImage(relativePath: "../../etc/passwd")
    }

    func testEmptyAndSlashRelativePathsDoNotDeleteBaseDirectory() throws {
        let uniqueTempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: uniqueTempDir, withIntermediateDirectories: true)
        
        // Create a canary file in the base directory
        let canaryURL = uniqueTempDir.appendingPathComponent("canary.txt")
        try "important_data".write(to: canaryURL, atomically: true, encoding: .utf8)
        
        let storage = BillStorageManager(baseDirectory: uniqueTempDir)
        
        // Deleting empty or slash relative paths must NOT delete the base directory or its contents
        storage.deleteBillImage(relativePath: "")
        storage.deleteBillImage(relativePath: "/")
        storage.deleteBillImage(relativePath: "///")
        storage.deleteBillImage(relativePath: "Bills")
        storage.deleteBillImage(relativePath: "Bills/")
        storage.deleteBillImage(relativePath: "/Bills/")
        
        // Verify base directory and canary file are completely intact
        XCTAssertTrue(FileManager.default.fileExists(atPath: uniqueTempDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: canaryURL.path))
        
        // Also verify load returns nil for these paths
        XCTAssertNil(storage.loadBillImage(relativePath: ""))
        XCTAssertNil(storage.loadBillImage(relativePath: "/"))
        XCTAssertNil(storage.loadBillImage(relativePath: "Bills"))
        XCTAssertNil(storage.loadBillImage(relativePath: "Bills/"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: uniqueTempDir)
    }

    func testSaveMultipleImagesGenerateUniquePaths() throws {
        let storage = BillStorageManager(baseDirectory: FileManager.default.temporaryDirectory)
        let sampleImage = UIImage(systemName: "star.fill") ?? UIImage()
        
        let path1 = try storage.saveBillImage(sampleImage)
        let path2 = try storage.saveBillImage(sampleImage)
        
        XCTAssertNotEqual(path1, path2)
        XCTAssertTrue(path1.contains("bill_"))
        XCTAssertTrue(path2.contains("bill_"))
        
        storage.deleteBillImage(relativePath: path1)
        storage.deleteBillImage(relativePath: path2)
    }
}
