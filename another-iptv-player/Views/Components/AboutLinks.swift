import SwiftUI

/// URU2.COM: rows of the "About" section — website, contact and open-source licences.
enum URU2Brand {
    static let websiteURL = URL(string: "https://www.uru2.com")!
    static let contactEmail = "contacto@uru2.com"
    static let contactURL = URL(string: "mailto:contacto@uru2.com")!
}

struct AboutLinks: View {
    var body: some View {
        linkRow(
            destination: URU2Brand.websiteURL,
            title: L("settings.about.website.title"),
            detail: "www.uru2.com"
        )
        linkRow(
            destination: URU2Brand.contactURL,
            title: L("settings.about.contact.title"),
            detail: URU2Brand.contactEmail
        )
        NavigationLink(L("settings.about.licenses.title")) {
            OpenSourceLicensesView()
        }
    }

    private func linkRow(destination: URL, title: String, detail: String) -> some View {
        Link(destination: destination) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    // The colour, not the hierarchical style: inside a link
                    // `.secondary` is a faded tint.
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// The MIT licence requires its copyright and permission notice to ship with the app.
struct OpenSourceLicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("settings.about.licenses.intro"))
                    .font(.subheadline)
                Text("Another IPTV Player — github.com/bsogulcan/another-iptv-player")
                    .font(.footnote.weight(.semibold))
                Text(Self.mitNotice)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Divider()
                Text("KSPlayer — github.com/kingslay/KSPlayer")
                    .font(.footnote.weight(.semibold))
                Text("GNU General Public License v3.0 (GPL-3.0)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("FFmpegKit / FFmpeg — github.com/kingslay/FFmpegKit")
                    .font(.footnote.weight(.semibold))
                Text("GNU Lesser General Public License (LGPL)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("GRDB.swift, GRDBQuery, Nuke — MIT License")
                    .font(.footnote.weight(.semibold))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(L("settings.about.licenses.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    static let mitNotice = """
    MIT License

    Copyright 2025 Another IPTV Player

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    """
}
