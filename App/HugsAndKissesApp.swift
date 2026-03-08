// HugsAndKissesApp.swift
// App entry point – requires iOS 16+ (WidgetKit lock-screen support)

import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseFirestore

@main
struct HugsAndKissesApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                // Pass state into the delegate so it can forward notifications
                .onAppear { delegate.appState = appState }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                handlePendingWidgetAction()
            }
        }
    }

    private func handlePendingWidgetAction() {
        guard let action = SharedDefaults.string(for: .pendingAction),
              !action.isEmpty,
              let myUID      = SharedDefaults.string(for: .myUID),
              let partnerUID = SharedDefaults.string(for: .partnerUID),
              let myName     = SharedDefaults.string(for: .myName)
        else { return }

        // Clear immediately so we don't send twice
        SharedDefaults.set("", for: .pendingAction)

        let settings = UserHapticSettings.load()
        Task {
            try? await FirebaseService.shared.send(
                type: action,
                senderUID: myUID,
                senderName: myName,
                recipientUID: partnerUID,
                settings: settings
            )
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
