import Foundation
import Combine

/// URU2.COM: the "Top 10" ranking published by uru2's server.
///
/// The endpoint only lists Xtream ids, most watched first. Names and posters always
/// come from the user's own catalog: an id the user's list does not have is skipped,
/// and with fewer than `URU2RankingMatch.minimumItems` matches the shelf is not shown.
/// The ids belong to one panel, so the ranking only applies to playlists of
/// `rankedHosts`: another panel may use the same number for another title.
@MainActor
final class URU2Ranking: ObservableObject {
    static let shared = URU2Ranking()

    static let endpoint = URL(string: "https://botcode.jp2000.xyz/uru2/most_watched.json")!
    /// Panels whose ids the ranking refers to. Add a host here to enable it there.
    static let rankedHosts: Set<String> = ["tv.uru2.com"]
    private static let refreshInterval: TimeInterval = 300

    @Published private(set) var movies: [Int] = []
    @Published private(set) var series: [Int] = []
    /// Goes up whenever either list changes; views key their matching on it.
    @Published private(set) var version = 0

    private var lastFetch: Date?
    private var isFetching = false

    static func appliesTo(_ playlist: Playlist) -> Bool {
        guard playlist.type == PlaylistKind.xtream.rawValue else { return false }
        let raw = playlist.serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let withScheme = raw.contains("://") ? raw : "http://" + raw
        guard let host = URL(string: withScheme)?.host()?.lowercased() else { return false }
        return rankedHosts.contains(host)
    }

    /// Fetches the ranking at most every five minutes, and only for ranked playlists.
    func refreshIfNeeded(for playlist: Playlist) async {
        guard Self.appliesTo(playlist), !isFetching else { return }
        if let lastFetch, Date().timeIntervalSince(lastFetch) < Self.refreshInterval { return }
        isFetching = true
        defer { isFetching = false }
        let request = URLRequest(url: Self.endpoint, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 15)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let payload = try JSONDecoder().decode(URU2RankingPayload.self, from: data)
            lastFetch = Date()
            if payload.movies != movies || payload.series != series {
                movies = payload.movies
                series = payload.series
                version &+= 1
            }
        } catch {
            Log.error("URU2Ranking", "fetch failed: \(error.localizedDescription)")
        }
    }
}

nonisolated struct URU2RankingPayload: Decodable, Sendable {
    let movies: [Int]
    let series: [Int]

    enum CodingKeys: String, CodingKey { case movies, series }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movies = (try? c.decode([Int].self, forKey: .movies)) ?? []
        series = (try? c.decode([Int].self, forKey: .series)) ?? []
    }
}

/// Matching of the ranking against the user's catalog. Runs off the main actor: it is
/// one pass over the whole catalog.
nonisolated enum URU2RankingMatch {
    static let shelfLimit = 10
    static let minimumItems = 5

    static func movies(ids: [Int], in streams: [VODWithCategory], hidden: Set<String>) -> [DBVODStream] {
        guard !ids.isEmpty else { return [] }
        let wanted = Set(ids)
        var found: [Int: DBVODStream] = [:]
        for item in streams {
            let stream = item.stream
            guard wanted.contains(stream.streamId), found[stream.streamId] == nil,
                  !hidden.contains(stream.categoryId ?? "") else { continue }
            found[stream.streamId] = stream
        }
        return shelf(ids.compactMap { found[$0] })
    }

    static func series(ids: [Int], in items: [SeriesWithCategory], hidden: Set<String>) -> [DBSeries] {
        guard !ids.isEmpty else { return [] }
        let wanted = Set(ids)
        var found: [Int: DBSeries] = [:]
        for item in items {
            let series = item.series
            guard wanted.contains(series.seriesId), found[series.seriesId] == nil,
                  !hidden.contains(series.categoryId ?? "") else { continue }
            found[series.seriesId] = series
        }
        return shelf(ids.compactMap { found[$0] })
    }

    private static func shelf<T>(_ ordered: [T]) -> [T] {
        let top = Array(ordered.prefix(shelfLimit))
        return top.count >= minimumItems ? top : []
    }
}
