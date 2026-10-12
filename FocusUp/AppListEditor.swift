import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Edits a set of apps stored by bundle ID.
struct AppListEditor: View {
    @Binding var bundleIDs: Set<String>
    let emptyMessage: LocalizedStringResource

    @State private var selection: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List(selection: $selection) {
                ForEach(bundleIDs.sorted(by: { AppMetadata(bundleID: $0) < AppMetadata(bundleID: $1) }), id: \.self) {
                    bundleID in
                    let app = AppMetadata(bundleID: bundleID)
                    Label {
                        Text(app.name)
                    } icon: {
                        Image(nsImage: app.icon).resizable().frame(width: 16, height: 16)
                    }
                }
            }
            .overlay {
                if bundleIDs.isEmpty {
                    Text(emptyMessage).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                Menu {
                    ForEach(runningApps, id: \.bundleID) { app in
                        Button(app.name) { bundleIDs.insert(app.bundleID) }
                    }
                    Divider()
                    Button("Choose App…", action: chooseApp)
                } label: {
                    Image(systemName: "plus")
                }
                .menuIndicator(.hidden)
                .fixedSize()

                Button {
                    bundleIDs.subtract(selection)
                    selection = []
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selection.isEmpty)
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
        .border(.separator)
    }

    private var runningApps: [AppMetadata] {
        let ownBundleID = Bundle.main.bundleIdentifier
        let apps = NSWorkspace.shared.runningApplications.compactMap { app -> AppMetadata? in
            guard app.activationPolicy == .regular, let bundleID = app.bundleIdentifier, bundleID != ownBundleID,
                !bundleIDs.contains(bundleID)
            else { return nil }
            return AppMetadata(bundleID: bundleID)
        }
        return Array(Set(apps)).sorted()
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            if let bundleID = Bundle(url: url)?.bundleIdentifier { bundleIDs.insert(bundleID) }
        }
    }
}

struct AppMetadata: Hashable, Comparable {
    let bundleID: String
    let name: String

    init(bundleID: String) {
        self.bundleID = bundleID
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        name = url.map { FileManager.default.displayName(atPath: $0.path).replacing(".app", with: "") } ?? bundleID
    }

    var icon: NSImage {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID).map {
            NSWorkspace.shared.icon(forFile: $0.path)
        } ?? NSWorkspace.shared.icon(for: .application)
    }

    static func < (lhs: AppMetadata, rhs: AppMetadata) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
