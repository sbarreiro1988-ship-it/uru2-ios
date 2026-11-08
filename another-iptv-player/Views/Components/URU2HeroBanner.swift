import SwiftUI

/// URU2.COM: the big poster card at the top of Movies and Series. Pages through the
/// newest titles of the user's own list by itself; "Watch" opens the title and
/// "My list" adds it to the favourites.
struct URU2HeroBanner<Item: Identifiable & Equatable, Destination: View>: View {
    let items: [Item]
    var containerWidth: CGFloat
    let playlistId: UUID
    /// "vod" or "series", as the favourites store keeps it.
    let favoriteType: String
    let favoriteId: (Item) -> Int
    let imageURL: (Item) -> URL?
    let title: (Item) -> String
    /// "Película · Acción · ★ 7.8"
    let meta: (Item) -> String
    let destination: (Item) -> Destination

    private static var interval: Duration { .seconds(7) }

    @State private var selection: Item.ID?
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var favorites = XtreamFavoriteStore.shared

    private var cardWidth: CGFloat { max(containerWidth - 32, 1) }
    private var cardHeight: CGFloat { min(cardWidth * 1.32, 560) }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(items) { item in
                card(item)
                    .tag(Optional(item.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: items.count > 1 ? .always : .never))
        .frame(height: cardHeight + 34)
        .padding(.top, 4)
        .onAppear {
            if selection == nil || !items.contains(where: { $0.id == selection }) {
                selection = items.first?.id
            }
        }
        .onChange(of: items) { _, new in
            if !new.contains(where: { $0.id == selection }) { selection = new.first?.id }
        }
        .task(id: scenePhase == .active) {
            guard scenePhase == .active, items.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.interval)
                guard !Task.isCancelled else { return }
                advance()
            }
        }
    }

    private func advance() {
        guard let index = items.firstIndex(where: { $0.id == selection }) else {
            selection = items.first?.id
            return
        }
        withAnimation(.easeInOut(duration: 0.45)) {
            selection = items[(index + 1) % items.count].id
        }
    }

    private func card(_ item: Item) -> some View {
        ZStack(alignment: .bottom) {
            // The whole poster opens the title.
            NavigationLink {
                destination(item)
            } label: {
                ZStack(alignment: .topLeading) {
                    CachedImage(
                        url: imageURL(item),
                        width: cardWidth,
                        height: cardHeight,
                        cornerRadius: 0,
                        contentMode: .fill,
                        iconName: "film",
                        loadProfile: .high
                    )
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.55), .black.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: cardWidth, height: cardHeight)

                    Text(L("uru2.banner.new"))
                        .font(.caption.weight(.heavy))
                        .textCase(.uppercase)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 5))
                        .foregroundStyle(.black)
                        .padding(14)
                }
            }
            .buttonStyle(.plain)

            // Title and buttons on top; the empty space lets taps through to the poster.
            VStack(spacing: 12) {
                Text(title(item))
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.6), radius: 6)
                    .allowsHitTesting(false)

                let metaText = meta(item)
                if !metaText.isEmpty {
                    Text(metaText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .allowsHitTesting(false)
                }

                HStack(spacing: 12) {
                    NavigationLink {
                        destination(item)
                    } label: {
                        Label(L("uru2.banner.open"), systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(.black)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    myListButton(item)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func myListButton(_ item: Item) -> some View {
        let id = favoriteId(item)
        let state = favorites.favoriteState(id, type: favoriteType, playlistId: playlistId)
        let isFavorite = state ?? false
        return Button {
            Task {
                if state == nil {
                    await favorites.toggle(id, type: favoriteType, playlistId: playlistId)
                } else {
                    await favorites.setFavorite(!isFavorite, streamId: id, type: favoriteType, playlistId: playlistId)
                }
            }
        } label: {
            Label(L("uru2.banner.my_list"), systemImage: isFavorite ? "checkmark" : "plus")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
    }
}
