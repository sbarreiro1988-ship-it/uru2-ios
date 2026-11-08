import SwiftUI

/// URU2.COM: paging banner at the top of Movies and Series with the newest titles of
/// the user's own list. Advances by itself every few seconds; a tap opens the title.
struct URU2HeroBanner<Item: Identifiable & Equatable, Destination: View>: View {
    let items: [Item]
    var containerWidth: CGFloat
    let imageURL: (Item) -> URL?
    let title: (Item) -> String
    let destination: (Item) -> Destination

    private static var height: CGFloat { 230 }
    private static var interval: Duration { .seconds(6) }

    @State private var selection: Item.ID?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selection) {
            ForEach(items) { item in
                NavigationLink {
                    destination(item)
                } label: {
                    page(item)
                }
                .buttonStyle(.plain)
                .tag(Optional(item.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: Self.height)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
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
        withAnimation(.easeInOut(duration: 0.4)) {
            selection = items[(index + 1) % items.count].id
        }
    }

    private func page(_ item: Item) -> some View {
        let width = max(containerWidth - 32, 1)
        return ZStack(alignment: .bottomLeading) {
            // Backdrop: the same poster, blurred and darkened.
            CachedImage(
                url: imageURL(item),
                width: width,
                height: Self.height,
                cornerRadius: 0,
                contentMode: .fill,
                iconName: "film",
                loadProfile: .high
            )
            .blur(radius: 18)
            .overlay(Color.black.opacity(0.45))

            HStack(alignment: .bottom, spacing: 14) {
                CachedImage(
                    url: imageURL(item),
                    width: 118,
                    height: 177,
                    cornerRadius: 10,
                    contentMode: .fill,
                    iconName: "film",
                    loadProfile: .high
                )
                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("uru2.banner.new"))
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.black)
                    Text(title(item))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Label(L("uru2.banner.open"), systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.bottom, 26)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(width: width, height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
