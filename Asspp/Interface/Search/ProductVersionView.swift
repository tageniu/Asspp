//
//  ProductVersionView.swift
//  Asspp
//
//  Created by luca on 15.09.2025.
//

import ApplePackage
import ButtonKit
import SwiftUI

struct ProductVersionView: View {
    let accountIdentifier: String
    let package: AppStore.AppPackage

    @StateObject private var dvm = Downloads.this
    @State private var hint: Hint?

    var body: some View {
        if let req = dvm.downloadRequest(forArchive: package) {
            NavigationLink(destination: PackageView(pkg: req)) {
                HStack {
                    Text(package.software.version)
                    Spacer()
                    Text("Show Download")
                }
            }
        } else {
            AsyncButton {
                do {
                    try await dvm.startDownload(for: package, accountID: accountIdentifier)
                    hint = Hint(message: String(localized: "Download Requested"), color: nil)
                } catch {
                    hint = Hint(message: String(localized: "Unable to retrieve download URL. Please try again later.") + "\n" + error.localizedDescription, color: .red)
                    throw error
                }
            } label: {
                VStack(alignment: .leading) {
                    HStack {
                        Text(package.software.version)
                        Spacer()
                        Text("Request Download")
                    }

                    if let hint {
                        Text(hint.message)
                            .foregroundStyle(hint.color ?? .primary)
                    }
                }
            }
            .disabledWhenLoading()
        }
    }
}
