import SwiftUI

/// This version's CHANGELOG section, shown once after an update.
struct WhatsNew: Equatable {
    static let fullChangelogURL = URL(string: "https://github.com/Luis-Sejer/snicker-gif/blob/main/CHANGELOG.md")!
    private static let lastSeenVersionKey = "lastSeenVersion"

    let version: String
    let notes: String

    /// Returns the notes the first time a newer version runs, and marks them seen. A fresh install gets nothing:
    /// there is no "new" for someone who just arrived.
    static func pending(defaults: UserDefaults = .standard, bundle: Bundle = .main) -> WhatsNew? {
        guard let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return nil }
        let lastSeen = defaults.string(forKey: lastSeenVersionKey)
        defaults.set(version, forKey: lastSeenVersionKey)
        // Versions before 1.3.0 didn't record this, so saved favorites or recents are what show an update.
        let isUpdate = lastSeen.map { Updater.isVersion(version, newerThan: $0) }
            ?? (defaults.object(forKey: "recents") != nil || defaults.object(forKey: "favorites") != nil)
        guard isUpdate,
              let url = bundle.url(forResource: "whats-new", withExtension: "md"),
              let notes = try? String(contentsOf: url, encoding: .utf8),
              !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return WhatsNew(version: version, notes: notes)
    }
}

struct WhatsNewView: View {
    let whatsNew: WhatsNew
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("What’s New in Snicker \(whatsNew.version)")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        lineView(line)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
            }

            VStack(spacing: 10) {
                Button(action: dismiss) {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                Link("See the Full Changelog", destination: WhatsNew.fullChangelogURL)
                    .font(.callout)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }

    private var lines: [String] {
        whatsNew.notes
            .replacingOccurrences(of: "<kbd>", with: "")
            .replacingOccurrences(of: "</kbd>", with: "")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// The CHANGELOG uses "### Added"-style headings and "- " bullets; anything else shows as plain text.
    @ViewBuilder
    private func lineView(_ line: String) -> some View {
        if line.hasPrefix("### ") {
            Text(line.dropFirst(4))
                .font(.headline)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
        } else if line.hasPrefix("- ") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•").foregroundStyle(.secondary).accessibilityHidden(true)
                Text(markdown(String(line.dropFirst(2))))
            }
        } else {
            Text(markdown(line))
        }
    }

    private func markdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}
