//
//  AppStore.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Foundation

@MainActor
class AppStore: ObservableObject {
    @PublishedPersist(key: "Accounts", defaultValue: [], keychain: "wiki.qaq.Asspp.Accounts")
    var accounts: [UserAccount]

    @PublishedPersist(key: "DeviceIdentifier", defaultValue: "")
    var deviceIdentifier: String

    @PublishedPersist(key: "DemoMode", defaultValue: false)
    var demoMode: Bool

    static let this = AppStore()

    private init() {
        if deviceIdentifier.isEmpty {
            do {
                let systemIdentifier = try ApplePackage.DeviceIdentifier.system()
                deviceIdentifier = systemIdentifier
                logger.info("obtained system device identifier")
            } catch {
                logger.warning("failed to get system device identifier, falling back to random one: \(error)")
                let randomIdentifier = ApplePackage.DeviceIdentifier.random()
                deviceIdentifier = randomIdentifier
            }
        }
        logger.info("using device identifier: \(deviceIdentifier)")
        ApplePackage.Configuration.deviceIdentifier = deviceIdentifier
    }

    @discardableResult
    func save(email: String, account: ApplePackage.Account) -> UserAccount {
        logger.info("saving account for user")
        let account = UserAccount(account: account)
        accounts = (accounts.filter { $0.account.email != email } + [account])
            .sorted { $0.account.email < $1.account.email }
        return account
    }

    func delete(id: UserAccount.ID) {
        logger.info("deleting account id: \(id)")
        accounts = accounts.filter { $0.id != id }
    }

    var possibleRegions: Set<String> {
        Set(accounts.compactMap { ApplePackage.Configuration.countryCode(for: $0.account.store) })
    }

    func eligibleAccounts(for region: String) -> [UserAccount] {
        accounts.filter { ApplePackage.Configuration.countryCode(for: $0.account.store) == region }
    }

    nonisolated func withAccount<T>(id: String, _ body: (inout UserAccount) async throws -> T) async throws -> T {
        if let idx = await accounts.firstIndex(where: { $0.id == id }) {
            var account = await accounts[idx]
            let result = try await body(&account)
            let updatedAccount = account
            await MainActor.run { accounts[idx] = updatedAccount }
            return result
        } else {
            throw AuthenticationError.accountNotFound
        }
    }
}
