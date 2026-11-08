import SwiftUI

// URU2.COM: browse pieces for the home screens of Movies and Series.

// MARK: - "New" badge

nonisolated enum URU2Fresh {
    /// A title counts as new for a week after the panel added it.
    static let window: TimeInterval = 7 * 24 * 3600

    /// `unix` is the panel's `added` / `last_modified`: seconds since 1970, as text.
    static func isNew(_ unix: String?, now: Date = Date()) -> Bool {
        guard let unix, let seconds = Double(unix), seconds > 0 else { return false }
        let age = now.timeIntervalSince1970 - seconds
        return age >= 0 && age < window
    }
}

struct URU2NewBadge: View {
    var body: some View {
        Text(L("uru2.badge.new"))
            .font(.caption2.weight(.heavy))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(.black)
            .accessibilityLabel(L("uru2.badge.new"))
    }
}

// MARK: - Category chips

/// Row of category chips under the title. "Categories" opens the full picker, every
/// other chip jumps to its shelf.
struct URU2CategoryChips: View {
    let categories: [DBCategory]
    let onShowAll: () -> Void
    let onSelect: (String) -> Void

    private static let limit = 15

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button(action: onShowAll) {
                    HStack(spacing: 6) {
                        Text(L("uru2.chips.all"))
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .modifier(ChipStyle())
                }
                ForEach(categories.prefix(Self.limit)) { category in
                    Button {
                        onSelect(category.id)
                    } label: {
                        Text(category.name)
                            .lineLimit(1)
                            .modifier(ChipStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private struct ChipStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                )
        }
    }
}

// MARK: - Top 10

/// "The 10 most watched": posters with their rank drawn large and outlined behind them.
struct URU2Top10Shelf<Item: Identifiable & Equatable, Destination: View>: View {
    let title: String
    let items: [Item]
    let imageURL: (Item) -> URL?
    let iconName: String
    let destination: (Item) -> Destination

    private static var posterWidth: CGFloat { 112 }
    private static var posterHeight: CGFloat { 166 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShelfHeaderLabel(title, showsChevron: false)
                .padding(.horizontal, BrowseMetrics.pageMargin)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            destination(item)
                        } label: {
                            HStack(alignment: .bottom, spacing: -24) {
                                URU2RankNumber(rank: index + 1, height: Self.posterHeight)
                                CachedImage(
                                    url: imageURL(item),
                                    width: Self.posterWidth,
                                    height: Self.posterHeight,
                                    cornerRadius: BrowseMetrics.posterCornerRadius,
                                    contentMode: .fill,
                                    iconName: iconName,
                                    loadProfile: .shelf
                                )
                                .shadow(color: .black.opacity(0.6), radius: 6, x: -4)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(index + 1)")
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollClipDisabled()
        }
        .padding(.vertical, 8)
    }
}

/// A rank drawn as a heavy number with a light outline, filled with the background.
struct URU2RankNumber: View {
    let rank: Int
    let height: CGFloat

    private static let outline: [CGSize] = [
        CGSize(width: -2, height: 0), CGSize(width: 2, height: 0),
        CGSize(width: 0, height: -2), CGSize(width: 0, height: 2),
        CGSize(width: -1.5, height: -1.5), CGSize(width: 1.5, height: 1.5),
        CGSize(width: -1.5, height: 1.5), CGSize(width: 1.5, height: -1.5),
    ]

    var body: some View {
        let number = Text("\(rank)")
            .font(.system(size: height * 0.92, weight: .black))
            .tracking(rank >= 10 ? -10 : 0)
        ZStack {
            ForEach(0..<Self.outline.count, id: \.self) { i in
                number
                    .foregroundStyle(Color.white.opacity(0.75))
                    .offset(Self.outline[i])
            }
            number.foregroundStyle(Color(.systemBackground))
        }
        .fixedSize()
        .frame(height: height, alignment: .bottom)
        .offset(y: height * 0.12)
        .accessibilityHidden(true)
    }
}

// MARK: - Meta line

nonisolated enum URU2Meta {
    /// "Película · Acción · ★ 7.8" from what the catalog knows.
    static func line(kind: String, genre: String?, rating: String?) -> String {
        var parts = [kind]
        if let genre = genre?.split(separator: ",").first?.trimmingCharacters(in: .whitespaces), !genre.isEmpty {
            parts.append(genre)
        }
        if let rating, let value = Double(rating), value > 0 {
            parts.append("★ " + String(format: "%.1f", value))
        }
        return parts.joined(separator: " · ")
    }
}
