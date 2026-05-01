//
//  ProfileImageManager.swift
//  RecoveryOS
//

import UIKit
import Combine

// Manages saving and loading the user's profile picture to/from the app's
// Documents directory. Using the file system rather than SwiftData keeps
// large binary data out of the SQLite database, which is better for performance.
//
// The singleton pattern mirrors HealthKitManager and NotificationManager so
// any view in the hierarchy can access the current image without prop-drilling.
// @MainActor ensures @Published updates are always delivered on the main thread.
@MainActor
final class ProfileImageManager: ObservableObject {

    static let shared = ProfileImageManager()
    private init() { load() }

    // The current profile image. nil means no photo has been set yet,
    // which tells views to show the default person.fill SF Symbol instead.
    @Published var image: UIImage? = nil

    // MARK: - File location

    // Always write to the same filename so loading is trivial and there is
    // never more than one profile image taking up space in Documents.
    private static let filename = "profile_image.jpg"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    // MARK: - Save

    // Compresses to JPEG at 80% quality before writing so the file stays
    // small enough for a profile photo displayed at small sizes on screen.
    // The .atomic option writes to a temp file first and then renames, which
    // prevents a corrupt file if the app is killed mid-write.
    func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
        self.image = image
    }

    // MARK: - Load

    // Called once during init so the image is ready before any view appears.
    // Silent no-op if no file exists yet (new install or after delete()).
    func load() {
        guard FileManager.default.fileExists(atPath: Self.fileURL.path) else { return }
        image = UIImage(contentsOfFile: Self.fileURL.path)
    }

    // MARK: - Delete

    // Removes the saved file and clears the published image so views revert
    // to the default avatar immediately without needing to reload.
    func delete() {
        try? FileManager.default.removeItem(at: Self.fileURL)
        image = nil
    }
}
