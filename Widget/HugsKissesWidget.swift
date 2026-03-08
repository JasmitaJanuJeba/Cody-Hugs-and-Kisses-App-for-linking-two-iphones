// HugsKissesWidget.swift
// Lock screen widgets for the bottom-row accessory circles
// Targets: accessoryCircular (replaces the flashlight / camera spots)
//
// iOS 16+ required for lock screen widgets.
// iOS 17+ required for interactive (Button/Toggle) widgets.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct HKEntry: TimelineEntry {
    var date: Date
    var isPaired: Bool
    var hugIsLit: Bool
    var kissIsLit: Bool
    var litUntil: Date?
}

// MARK: - Timeline Provider

struct HKProvider: TimelineProvider {

    typealias Entry = HKEntry

    func placeholder(in context: Context) -> HKEntry {
        HKEntry(date: .now, isPaired: true, hugIsLit: false, kissIsLit: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (HKEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HKEntry>) -> Void) {
        let entry  = makeEntry()
        var entries = [entry]

        // If a light-up is active, schedule a refresh entry after it expires
        if let until = entry.litUntil, until > .now {
            let expiredEntry = HKEntry(date: until,
                                       isPaired: entry.isPaired,
                                       hugIsLit: false,
                                       kissIsLit: false,
                                       litUntil: nil)
            entries.append(expiredEntry)
            let timeline = Timeline(entries: entries, policy: .after(until.addingTimeInterval(1)))
            completion(timeline)
        } else {
            // Refresh every 5 minutes to stay in sync
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
            completion(Timeline(entries: entries, policy: .after(refreshDate)))
        }
    }

    private func makeEntry() -> HKEntry {
        let litUntil = SharedDefaults.date(for: .litUpUntil)
        let stillLit = litUntil.map { $0 > Date() } ?? false
        let litType  = SharedDefaults.string(for: .litUpType)

        return HKEntry(
            date: .now,
            isPaired: SharedDefaults.bool(for: .isPaired),
            hugIsLit:  stillLit && litType == "hug",
            kissIsLit: stillLit && litType == "kiss",
            litUntil:  stillLit ? litUntil : nil
        )
    }
}

// MARK: - Hug Widget

struct HugWidget: Widget {
    let kind = "HugWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HKProvider()) { entry in
            HugWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Hug")
        .description("Send your partner a warm hug from your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Kiss Widget

struct KissWidget: Widget {
    let kind = "KissWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HKProvider()) { entry in
            KissWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Kiss")
        .description("Send your partner a kiss from your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Hug Widget View

struct HugWidgetView: View {
    var entry: HKEntry

    var body: some View {
        Button(intent: SendHugIntent()) {
            ZStack {
                // Liquid glass circle background
                Circle()
                    .fill(entry.hugIsLit
                          ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.41, blue: 0.61),  // litPink
                                        Color(red: 0.90, green: 0.25, blue: 0.50)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                          : AnyShapeStyle(.regularMaterial))

                // Specular highlight (top-left glint)
                if !entry.hugIsLit {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .padding(5)
                        .offset(x: -2, y: -3)
                }

                // Stroke
                Circle()
                    .strokeBorder(
                        entry.hugIsLit
                            ? Color(red: 1.0, green: 0.75, blue: 0.87)
                            : Color.white.opacity(0.35),
                        lineWidth: entry.hugIsLit ? 1.5 : 0.8
                    )

                // Emoji
                Text("🤗")
                    .font(.system(size: 22))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            }
        }
        .buttonStyle(.plain)
        // Pink glow when lit
        .shadow(
            color: entry.hugIsLit
                ? Color(red: 1.0, green: 0.41, blue: 0.61).opacity(0.8)
                : .clear,
            radius: 8
        )
        .widgetURL(URL(string: "hugsandkisses://hug"))
        .invalidatableContent()
    }
}

// MARK: - Kiss Widget View

struct KissWidgetView: View {
    var entry: HKEntry

    var body: some View {
        Button(intent: SendKissIntent()) {
            ZStack {
                Circle()
                    .fill(entry.kissIsLit
                          ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.41, blue: 0.61),
                                        Color(red: 0.90, green: 0.25, blue: 0.50)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                          : AnyShapeStyle(.regularMaterial))

                if !entry.kissIsLit {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .padding(5)
                        .offset(x: -2, y: -3)
                }

                Circle()
                    .strokeBorder(
                        entry.kissIsLit
                            ? Color(red: 1.0, green: 0.75, blue: 0.87)
                            : Color.white.opacity(0.35),
                        lineWidth: entry.kissIsLit ? 1.5 : 0.8
                    )

                Text("💋")
                    .font(.system(size: 22))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            }
        }
        .buttonStyle(.plain)
        .shadow(
            color: entry.kissIsLit
                ? Color(red: 1.0, green: 0.41, blue: 0.61).opacity(0.8)
                : .clear,
            radius: 8
        )
        .widgetURL(URL(string: "hugsandkisses://kiss"))
        .invalidatableContent()
    }
}

// MARK: - Widget Bundle

@main
struct HKWidgetBundle: WidgetBundle {
    var body: some Widget {
        HugWidget()
        KissWidget()
    }
}
