//
//  AppDelegate+iOS.swift
//  Asspp
//

#if canImport(UIKit)
    import Combine
    import UIKit

    class AppDelegate: NSObject, UIApplicationDelegate {
        var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
        var cancellable: AnyCancellable?

        func application(
            _: UIApplication,
            didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil,
        ) -> Bool {
            Task { @MainActor in
                self.observeDownloadCount()
            }
            return true
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
            UIApplication.shared.isIdleTimerDisabled = count > 0
            BackgroundAudioPlayer.shared.setActive(count > 0)
        }

        func applicationWillResignActive(_: UIApplication) {
            guard Downloads.this.runningTaskCount > 0 else { return }
            let task = UIApplication.shared.beginBackgroundTask(withName: "Downloads") {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = .invalid
            }
            backgroundTaskIdentifier = task
        }

        func applicationWillEnterForeground(_: UIApplication) {
            guard backgroundTaskIdentifier != .invalid else { return }
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
#endif
