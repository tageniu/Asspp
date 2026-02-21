//
//  AccountView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import SwiftUI

struct AccountView: View {
    @StateObject private var vm = AppStore.this
    @State private var addAccount = false
    @State private var selectedID: AppStore.UserAccount.ID?

    var body: some View {
        #if os(macOS)
            macOSBody
        #else
            iOSBody
        #endif
    }

    #if os(macOS)
        private var macOSBody: some View {
            NavigationStack {
                accountsTable
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .navigationTitle("Accounts")
                    .toolbar { macToolbar }
            }
            .sheet(isPresented: $addAccount) {
                AddAccountView()
                    .frame(minWidth: 480, idealWidth: 520, minHeight: 340, idealHeight: 380)
            }
            .macHiddenToolbarBackground()
        }

        private var accountsTable: some View {
            Table(vm.accounts, selection: $selectedID) {
                TableColumn("Email") { account in
                    Text(account.account.email)
                        .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TableColumn("Region") { account in
                    Text(account.account.store)
                }
                .width(min: 40, ideal: 60, max: 80)

                TableColumn("Storefront") { account in
                    Text(ApplePackage.Configuration.countryCode(for: account.account.store) ?? "-")
                }
                .width(min: 60, ideal: 80, max: 120)

                TableColumn("") { account in
                    NavigationLink {
                        AccountDetailView(accountId: account.id)
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.borderless)
                }
                .width(32)
            }
            .contextMenu(forSelectionType: AppStore.UserAccount.ID.self) { ids in
                if let id = ids.first {
                    NavigationLink {
                        AccountDetailView(accountId: id)
                    } label: {
                        Text("View Details")
                    }
                }
            }
            .navigationDestination(for: AppStore.UserAccount.ID.self) { id in
                AccountDetailView(accountId: id)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if vm.accounts.isEmpty {
                    CompatContentUnavailableView(
                        label: {
                            Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
                        },
                        description: {
                            Text("Add an Apple ID to start downloading IPA packages.")
                        },
                        actions: {
                            Button("Add Account") { addAccount.toggle() }
                        },
                    )
                    .padding()
                }
            }
        }

        private var footer: some View {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.title3)
                Text("Accounts are stored securely in your Keychain and can be removed at any time from the detail view.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        @ToolbarContentBuilder
        private var macToolbar: some ToolbarContent {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addAccount.toggle()
                } label: {
                    Label("Add Account", systemImage: "plus")
                }
            }
        }
    #endif

    #if !os(macOS)
        private var iOSBody: some View {
            NavigationView {
                Group {
                    if vm.accounts.isEmpty {
                        CompatContentUnavailableView(
                            label: {
                                Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
                            },
                            description: {
                                Text("Add an Apple ID to start downloading IPA packages.")
                            },
                            actions: {
                                Button("Add Account") { addAccount.toggle() }
                            },
                        )
                    } else {
                        Form {
                            Section {
                                ForEach(vm.accounts) { account in
                                    NavigationLink(destination: AccountDetailView(accountId: account.id)) {
                                        HStack {
                                            Text(account.account.email)
                                                .redacted(reason: .placeholder, isEnabled: vm.demoMode)
                                            Spacer()
                                        }
                                        .badge(ApplePackage.Configuration.countryCode(for: account.account.store) ?? account.account.store)
                                    }
                                }
                            } header: {
                                Text("Apple IDs")
                            } footer: {
                                Text("Your accounts are saved in your Keychain and will be synced across devices with the same iCloud account signed in.")
                            }
                        }
                        .groupedFormStyle()
                    }
                }
                .navigationTitle("Accounts")
                .toolbar {
                    ToolbarItem {
                        Button {
                            addAccount.toggle()
                        } label: {
                            Label("Add Account", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .sheet(isPresented: $addAccount) {
                NavigationView {
                    AddAccountView()
                }
                .navigationViewStyle(.stack)
            }
        }
    #endif
}
