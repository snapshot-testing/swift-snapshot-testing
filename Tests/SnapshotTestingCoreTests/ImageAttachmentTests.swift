#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
import CoreGraphics
import Foundation
import SnapshotTesting
import Testing

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Image assertions under Swift Testing, with images generated in memory instead of recorded ones.
@MainActor
@Suite("Image assertions")
struct ImageAttachmentTests {

    #if os(macOS)
    typealias PlatformImage = NSImage
    #else
    typealias PlatformImage = UIImage
    #endif

    private func solid(_ value: UInt8) -> PlatformImage {
        let bytes = [UInt8](repeating: value, count: 16 * 16 * 4)
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cgImage = CGImage(
            width: 16,
            height: 16,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 64,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        #if os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: 16, height: 16))
        #else
        return UIImage(cgImage: cgImage)
        #endif
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func aRecordedImageMatchesTheNextRun() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try withKnownIssue {
            try assert(of: solid(100), as: .image, named: "a", record: .missing, snapshotDirectory: directory.path)
        } matching: {
            ($0.comments.first?.rawValue ?? "").contains("Automatically recorded snapshot")
        }

        try assert(of: solid(100), as: .image, named: "a", record: .never, snapshotDirectory: directory.path)
    }

    @Test func aDifferentImageFailsAndCarriesTheReferenceTheFailureAndTheDifference() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try withKnownIssue {
            try assert(of: solid(100), as: .image, named: "a", record: .missing, snapshotDirectory: directory.path)
        }

        // The three images are attached to the failing test; the issue carries the explanation.
        try withKnownIssue {
            try assert(of: solid(220), as: .image, named: "a", record: .never, snapshotDirectory: directory.path)
        } matching: {
            ($0.comments.first?.rawValue ?? "").contains("does not match reference.")
        }
    }

    @Test func aToleranceLetsSmallDifferencesPass() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try withKnownIssue {
            try assert(of: solid(120), as: .image, named: "a", record: .missing, snapshotDirectory: directory.path)
        }

        try assert(
            of: solid(121),
            as: .image(precision: 1, perceptualPrecision: 0.99),
            named: "a",
            record: .never,
            snapshotDirectory: directory.path
        )
    }
}
#endif
