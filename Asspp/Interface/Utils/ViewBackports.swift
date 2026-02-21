//
//  ViewBackports.swift
//  Asspp
//
//  Created by luca on 19.09.2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func onChangeCompat<Value: Equatable>(of value: Value, perform action: @escaping () -> Void) -> some View {
        onChange(of: value) { _ in action() }
    }

    @ViewBuilder
    func groupedFormStyle() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            self.formStyle(.grouped)
        } else {
            self
        }
    }

    @ViewBuilder
    func mediumAndLargeDetents() -> some View {
        #if os(iOS)
            if #available(iOS 16.0, *) {
                presentationDetents([.medium, .large])
            } else {
                self
            }
        #else
            self
        #endif
    }

    @ViewBuilder
    func neverMinimizeTab() -> some View {
        #if os(iOS)
            #if compiler(>=6.2)
                if #available(iOS 26.0, *) {
                    tabBarMinimizeBehavior(.never)
                } else {
                    self
                }
            #else
                self
            #endif
        #else
            self
        #endif
    }

    @ViewBuilder
    func activateSearchWhenSearchTabSelected() -> some View {
        #if os(iOS)
            #if compiler(>=6.2)
                if #available(iOS 26.0, *) {
                    tabViewSearchActivation(.searchTabSelection)
                } else {
                    self
                }
            #else
                self
            #endif
        #else
            self
        #endif
    }

    @ViewBuilder
    func sidebarAdaptableTabView() -> some View {
        #if os(iOS)
            #if compiler(>=6.2)
                if #available(iOS 26.0, *) {
                    tabViewStyle(.sidebarAdaptable)
                } else {
                    self
                }
            #else
                self
            #endif
        #else
            self
        #endif
    }

    @ViewBuilder
    func smallControlSizeOnMac() -> some View {
        #if os(macOS)
            controlSize(.small)
        #else
            self
        #endif
    }

    @ViewBuilder
    func hide() -> some View {}
}

public extension ToolbarContent {
    @ToolbarContentBuilder
    nonisolated func hideSharedBackground() -> some ToolbarContent {
        #if compiler(>=6.2)
            if #available(iOS 26.0, macOS 26.0, *) {
                sharedBackgroundVisibility(.hidden)
            } else {
                self
            }
        #else
            self
        #endif
    }
}

// MARK: - ContentUnavailableView backport

struct CompatContentUnavailableView<Label: View, Description: View, Actions: View>: View {
    let label: Label
    let description: Description
    let actions: Actions

    init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder description: () -> Description,
        @ViewBuilder actions: () -> Actions
    ) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 12) {
            label
                .font(.title2)
                .foregroundStyle(.secondary)
            description
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
