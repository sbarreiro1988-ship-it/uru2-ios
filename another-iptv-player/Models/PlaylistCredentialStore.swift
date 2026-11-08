import Foundation
import GRDB
import Security

/// URU2.COM (upstream issue #100): Xtream passwords live in the Keychain, not in the
/// database. The `playlist.password` column is written empty for Xtream playlists;
/// `Playlist`'s Codable conformance fills the value back in from here when a row is
/// read, so API clients and URL building keep using `playlist.password` unchanged.
///
/// Items use `kSecAttrAccessibleAfterFirstUnlock`, so background refreshes after the
/// first unlock keep working, and they only travel in encrypted backups.
nonisolated enum PlaylistCredentialStore {
    static let service = "com.uru2.player.playlist-password"

    nonisolated struct KeychainError: Error, CustomStringConvertible {
        let status: OSStatus
        var description: String { "Keychain error \(status)" }
    }

    private static func baseQuery(_ id: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
        ]
    }

    /// Stores `password` for the playlist; an empty password removes the item.
    static func save(_ password: String, for id: UUID) throws {
        let query = baseQuery(id)
        guard !password.isEmpty else {
            delete(for: id)
            return
        }
        let attributes: [String: Any] = [
            kSecValueData as String: Data(password.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let add = query.merging(attributes) { _, new in new }
            status = SecItemAdd(add as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    static func load(for id: UUID) -> String? {
        var query = baseQuery(id)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                Log.error("Credentials", "Keychain read failed: \(status)")
            }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Whether this build can use the Keychain at all (unsigned simulator builds cannot).
    static func isAvailable() -> Bool {
        let probe = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        do {
            try save("probe", for: probe)
            delete(for: probe)
            return true
        } catch {
            return false
        }
    }

    static func delete(for id: UUID) {
        SecItemDelete(baseQuery(id) as CFDictionary)
    }

    /// Playlist ids that have an item, for removing the ones whose playlist is gone
    /// (Keychain items outlive an uninstall).
    static func storedIDs() -> [UUID] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let items = result as? [[String: Any]] else { return [] }
        return items.compactMap { ($0[kSecAttrAccount as String] as? String).flatMap(UUID.init(uuidString:)) }
    }

    /// Moves passwords still stored in the database into the Keychain and removes
    /// Keychain items of deleted playlists. Idempotent; run once per launch. A
    /// password whose Keychain write fails stays in the database.
    static func migrate(_ database: AppDatabase) async {
        guard isAvailable() else { return }
        do {
            let liveIds: Set<UUID> = try await database.write { db in
                let legacy = try Playlist
                    .filter(Column("type") == PlaylistKind.xtream.rawValue)
                    .filter(Column("password") != "")
                    .fetchAll(db)
                for playlist in legacy {
                    // `update` saves the password to the Keychain (willSave) and
                    // writes the column empty (encode).
                    try playlist.update(db)
                }
                return Set(try Playlist.fetchAll(db).map(\.id))
            }
            for id in storedIDs() where !liveIds.contains(id) {
                delete(for: id)
            }
        } catch {
            Log.error("Credentials", "migration skipped: \(error)")
        }
    }
}
