import FocusCore
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @Bindable var controller: FocusController

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettings(controller: controller)
            }
            Tab("Apps", systemImage: "square.grid.2x2") {
                AppsSettings(controller: controller)
            }
        }
        .frame(width: 480, height: 420)
    }
}

private struct GeneralSettings: View {
    @Bindable var controller: FocusController
    @Bindable private var updater = Updater.shared
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section {
                Toggle("Focus Mode", isOn: $controller.isEnabled)
                KeyboardShortcuts.Recorder("Toggle shortcut:", name: .toggleFocusMode)
            }
            Section {
                Picker("Scope", selection: $controller.scope) {
                    ForEach(FocusScope.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                if controller.needsAccessibilityPermission {
                    PermissionNote(
                        message: "Window scope needs Accessibility permission to follow the focused window.",
                        action: "Allow Accessibility…", perform: AXFocusMonitor.requestTrust)
                }
                Picker("Style", selection: $controller.style) {
                    ForEach(FocusStyle.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                LabeledContent("Intensity") {
                    Slider(value: $controller.intensity, in: 0...1)
                }
            }
            Section {
                Toggle("Automatically check for updates", isOn: $updater.automaticallyChecksForUpdates)
                Button("Check for Updates…") { updater.checkForUpdates() }
            }
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LaunchAtLogin.isEnabled = enabled
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
            }
        }
        .formStyle(.grouped)
    }
}

private struct AppsSettings: View {
    @Bindable var controller: FocusController

    var body: some View {
        Form {
            Section {
                AppListEditor(
                    bundleIDs: $controller.pinnedBundleIDs, emptyMessage: "No pinned apps"
                )
                .frame(height: 100)
            } header: {
                Text("Pinned Apps")
            } footer: {
                Text("Pinned apps are never blurred or hidden.")
                    .foregroundStyle(.secondary)
            }
            Section {
                AppListEditor(
                    bundleIDs: $controller.ignoredBundleIDs, emptyMessage: "No ignored apps"
                )
                .frame(height: 100)
                Toggle("Apps without a Dock icon never take focus", isOn: $controller.utilityAppsNeverTakeFocus)
            } header: {
                Text("Ignored Apps")
            } footer: {
                Text("When an ignored app becomes active, the previous app stays in focus.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
