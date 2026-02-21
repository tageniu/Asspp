//
//  AppDelegate+macOS.swift
//  Asspp
//

#if canImport(AppKit) && !canImport(UIKit)
    import AppKit
    import Combine

    class AppDelegate: NSObject, NSApplicationDelegate {
        var activityToken: NSObjectProtocol?
        var cancellable: AnyCancellable?

        func applicationDidFinishLaunching(_: Notification) {
            Task { @MainActor in
                self.observeDownloadCount()
            }
        }

        @MainActor
        private func observeDownloadCount() {
            // Run once immediately
            updateForDownloadCount()

            cancellable = Downloads.this.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateForDownloadCount()
                }
        }

        @MainActor
        private func updateForDownloadCount() {
            let count = Downloads.this.runningTaskCount
            NSApp.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
            updateProcessActivity(isDownloading: count > 0)
        }

        private func updateProcessActivity(isDownloading: Bool) {
            if isDownloading, activityToken == nil {
                activityToken = ProcessInfo.processInfo.beginActivity(
                    options: [.userInitiated, .idleSystemSleepDisabled],
                    reason: "Downloading App Store packages",
                )
            } else if !isDownloading, let token = activityToken {
                ProcessInfo.processInfo.endActivity(token)
                activityToken = nil
            }
        }

        func applicationDidBecomeActive(_: Notification) {
            if let mainWindow = NSApplication.shared.windows.first(where: {
                $0.identifier?.rawValue == "main-window"
            }) {
                mainWindow.styleMask = [.titled, .closable, .fullSizeContentView, .fullScreen]
            }
        }

        func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
            Downloads.this.runningTaskCount == 0
        }
    }
#endif
