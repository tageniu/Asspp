//
//  ProductView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import ButtonKit
import Kingfisher
import SwiftUI

struct ProductView: View {
    @StateObject private var archive: AppPackageArchive

    var region: String {
        archive.region
    }

    init(archive: AppStore.AppPackage, region: String) {
        _archive = StateObject(wrappedValue: AppPackageArchive(accountID: nil, region: region, package: archive))
    }

    @StateObject private var vm = AppStore.this
    @StateObject private var dvm = Downloads.this

    var eligibleAccounts: [AppStore.UserAccount] {
        vm.eligibleAccounts(for: region)
    }

    var account: AppStore.UserAccount? {
        vm.accounts.first { $0.id == selection }
    }

    @State private var selection: AppStore.UserAccount.ID = .init()
    @State private var licenseHint: String = ""
    @State private var showLicenseAlert = false
    @State private var hint: Hint?

    let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter
    }()

    var formattedSize: String? {
        guard let sizeBytes = archive.package.software.fileSizeBytes.flatMap(Int64.init(_:)) else {
            return nil
        }
        return sizeFormatter.string(fromByteCount: sizeBytes)
    }

    var body: some View {
        Form {
            accountSelector
            buttons
            packageHeader
            packageDetails
            packageDescription
            if account == nil {
                Section {
                    Text("No account available for this region.")
                        .foregroundStyle(.red)
                } header: {
                    Text("Error")
                } footer: {
                    Text("Please add an account in the Accounts page.")
                }
            }
            pricing
        }
        .groupedFormStyle()
        .onAppear {
            selection = eligibleAccounts.first?.id ?? .init()
        }
        .navigationTitle("Select Account")
        .alert("License Required", isPresented: $showLicenseAlert) {
            var confirmRole: ButtonRole?
            #if compiler(>=6.2)
                if #available(iOS 26.0, macOS 26.0, *) {
                    confirmRole = .confirm
                }
            #endif

            return Group {
                Button("Acquire License", role: confirmRole) {
                    guard let account else { return }
                    Task {
                        do {
                            try await vm.withAccount(id: account.id) { userAccount in
                                try await ApplePackage.Authenticator.rotatePasswordToken(for: &userAccount.account)
                                try await ApplePackage.Purchase.purchase(
                                    account: &userAccount.account,
                                    app: archive.package.software,
                                )
                            }
                            licenseHint = String(localized: "Request Succeeded")
                        } catch {
                            licenseHint = error.localizedDescription
                        }
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
        } message: {}
    }

    var packageHeader: some View {
        Section {
            PackageDisplayView(archive: archive.package)
            NavigationLink {
                ProductHistoryView(vm: AppPackageArchive(accountID: selection, region: region, package: archive.package))
            } label: {
                let badgeText = archive.releaseDate.flatMap { date in
                    Text(date.formatted(.relative(presentation: .numeric)))
                }

                Text("Version \(archive.package.software.version)")
                    .badge(badgeText)
            }
        } header: {
            Text("Package")
        }
    }

    var packageDetails: some View {
        Section {
            CopyableRow(label: "Bundle ID", value: archive.package.software.bundleID, monospaced: true)
            Text("Developer")
                .badge(archive.package.software.sellerName)
            if !archive.package.software.primaryGenreName.isEmpty {
                Text("Category")
                    .badge(archive.package.software.primaryGenreName)
            }
            if let formattedSize {
                Text("Size")
                    .badge(formattedSize)
            }
            Text("Compatibility")
                .badge("\(archive.package.software.minimumOsVersion)+")
            if archive.package.software.userRatingCount > 0 {
                Text("Rating")
                    .badge("\(String(format: "%.1f", archive.package.software.averageUserRating)) (\(archive.package.software.userRatingCount))")
            }
        } header: {
            Text("Details")
        }
    }

    var packageDescription: some View {
        Section {
            Text(archive.package.software.releaseNotes ?? "")
        } header: {
            Text("What's New")
        }
    }

    var pricing: some View {
        Section {
            Text("\(archive.formattedPrice ?? "N/A")")
            if archive.price == 0 {
                AsyncButton {
                    guard let account else { return }
                    try await vm.withAccount(id: account.id) { userAccount in
                        try await ApplePackage.Authenticator.rotatePasswordToken(for: &userAccount.account)
                        try await ApplePackage.Purchase.purchase(
                            account: &userAccount.account,
                            app: archive.package.software,
                        )
                    }
                    licenseHint = String(localized: "Request Succeeded")
                } label: {
                    Text("Acquire License")
                }
                .disabledWhenLoading()
                .disabled(account == nil)
            }
        } header: {
            Text("Pricing")
        } footer: {
            if licenseHint.isEmpty {
                Text("Acquiring a license is not available for paid apps. Purchase from the App Store first, then download here. If you've already purchased it, this may fail.")
            } else {
                Text(licenseHint)
                    .foregroundStyle(.red)
            }
        }
    }

    var accountSelector: some View {
        Section {
            Picker("Account", selection: $selection) {
                ForEach(eligibleAccounts) { account in
                    Text(account.account.email)
                        .id(account.id)
                }
            }
            .pickerStyle(.menu)
            .redacted(reason: .placeholder, isEnabled: vm.demoMode)
        } header: {
            Text("Account")
        } footer: {
            Text("You have searched this package with region \(region)")
        }
    }

    var buttons: some View {
        Section {
            if let req = dvm.downloadRequest(forArchive: archive.package) {
                NavigationLink(destination: PackageView(pkg: req)) {
                    Text("Show Download")
                }
            } else {
                AsyncButton {
                    guard let account else { return }
                    do {
                        try await dvm.startDownload(for: archive.package, accountID: account.id)
                        hint = Hint(message: String(localized: "Download Requested"), color: nil)
                    } catch {
                        if case ApplePackageError.licenseRequired = error, archive.package.software.price == 0 {
                            showLicenseAlert = true
                        } else {
                            hint = Hint(message: String(localized: "Unable to retrieve download URL. Please try again later.") + "\n" + error.localizedDescription, color: .red)
                        }
                        throw error
                    }
                } label: {
                    Text("Request Download")
                }
                .disabledWhenLoading()
                .disabled(account == nil)
            }
        } header: {
            Text("Download")
        } footer: {
            if let hint {
                Text(hint.message)
                    .foregroundStyle(hint.color ?? .primary)
            } else {
                Text("Package can be installed later in download page.")
            }
        }
    }
}

extension AppStore.AppPackage {
    var displaySupportedDevicesIcon: String {
        // TODO: assuming iPhone for now
        "iphone"
    }
}
