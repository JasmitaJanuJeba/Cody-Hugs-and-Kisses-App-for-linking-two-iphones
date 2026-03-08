// HugsAndKissesApp.swift
// App entry point – requires iOS 16+ (WidgetKit lock-screen support)

import SwiftUI
import UserNotifications
import FirebaseCore

@main
struct HugsAndKissesApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                // Pass state into the delegate so it can forward notifications
                .onAppear { delegate.appState = appState }
        }
    }
}

// MARK: - Root routing view

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
    }
}
