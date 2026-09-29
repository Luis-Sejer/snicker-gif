import AppKit

/// Asks GitHub whether a newer release exists, and installs it with the same script as the README.
@MainActor
final class Updater: ObservableObject {
    enum Phase {
        case idle, installing, failed
    }

    /// The outcome of a check the user asked for; background checks stay quiet.
    enum CheckStatus {
        case idle, checking, upToDate, failed
    }

    @Published private(set) var availableVersion: String?
    @Published private(set) var isSnoozed = false
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var checkStatus: CheckStatus = .idle

    static let releasesURL = URL(string: "https://github.com/Luis-Sejer/snicker-gif/releases/latest")!
    private static let latestReleaseAPI = URL(string: "https://api.github.com/repos/Luis-Sejer/snicker-gif/releases/latest")!
    private static let installCommand = "curl -fsSL https://raw.githubusercontent.com/Luis-Sejer/snicker-gif/main/install.sh | sh"
    private static let snoozeInterval: TimeInterval = 24 * 60 * 60
    /// Downloading 1–2 MB takes seconds; past this, something is stuck and GitHub is the way out.
    private static let installTimeout: Duration = .seconds(90)

    private var isFetching = false
    /// Kept in memory only, so restarting Snicker brings the reminder back before the day is up.
    private var snoozedUntil: Date?

    var showsReminder: Bool { availableVersion != nil && !isSnoozed }

    var installedVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// Called whenever the popover opens. Only Later holds the reminder back, until tomorrow.
    func checkIfDue() {
        if let snoozedUntil, Date() >= snoozedUntil {
            self.snoozedUntil = nil
            isSnoozed = false
        }
        guard !isSnoozed else { return }
        fetchLatest()
    }

    /// Check for Updates… in the menu or Settings: overrides Later and reports the result.
    func checkNow() {
        snoozedUntil = nil
        isSnoozed = false
        checkStatus = .checking
        fetchLatest()
    }

    func clearCheckResult() {
        if checkStatus != .checking { checkStatus = .idle }
    }

    // ponytail: a request per open. GitHub's API answers with max-age=60, so URLSession's cache absorbs quick
    // reopens and the 60-an-hour anonymous limit is only a risk for many users behind one office IP.
    private func fetchLatest() {
        guard !isFetching else { return }
        isFetching = true
        Task {
            defer { isFetching = false }
            let latest = await Self.latestVersion()
            if let latest {
                availableVersion = Self.isVersion(latest, newerThan: installedVersion) ? latest : nil
            }
            guard checkStatus == .checking else { return }
            // A found update shows as the usual reminder, so only "up to date" and failures need their own status.
            checkStatus = latest == nil ? .failed : (availableVersion == nil ? .upToDate : .idle)
        }
    }

    /// Nil when GitHub can't be reached; a background check just tries again on the next open.
    private static func latestVersion() async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(from: latestReleaseAPI),
              let release = try? JSONDecoder().decode(Release.self, from: data) else { return nil }
        return release.version
    }

    func remindLater() {
        snoozedUntil = Date().addingTimeInterval(Self.snoozeInterval)
        isSnoozed = true
    }

    /// The script normally quits Snicker and opens the new version itself. If Snicker is still running when the
    /// script succeeds, its `open` only brought this old copy forward, so quit and relaunch from here.
    func install() {
        phase = .installing
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", Self.installCommand]
        process.terminationHandler = { [weak self] process in
            let succeeded = process.terminationStatus == 0
            Task { @MainActor in
                if succeeded { Self.relaunch() } else { self?.phase = .failed }
            }
        }
        do {
            try process.run()
        } catch {
            phase = .failed
            return
        }
        Task { [weak self] in
            try? await Task.sleep(for: Self.installTimeout)
            if self?.phase == .installing { self?.phase = .failed }
        }
    }

    /// A detached shell waits for this process to exit, then opens the freshly installed app.
    private static func relaunch() {
        let appPath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done; open \"$0\"", appPath]
        try? process.run()
        NSApp.terminate(nil)
    }

    /// Compares dotted versions number by number, so 1.10.0 is newer than 1.9.0.
    nonisolated static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        candidate.compare(current, options: .numeric) == .orderedDescending
    }

    private struct Release: Decodable {
        let tagName: String
        var version: String { tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName }

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
        }
    }
}
