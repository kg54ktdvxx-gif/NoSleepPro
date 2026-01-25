//
//  AwakeAppMain.swift
//  AwakeApp
//
//  Main app entry point with MenuBarExtra
//

import SwiftUI

@main
struct AwakeAppMain: App {
    @StateObject private var appState = AppState()
    @StateObject private var caffeinateManager = CaffeinateManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(caffeinateManager)
        } label: {
            Image(systemName: appState.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
