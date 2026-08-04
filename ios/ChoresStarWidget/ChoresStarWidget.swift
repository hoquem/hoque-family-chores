//
//  ChoresStarWidget.swift
//  ChoresStarWidget
//
//  Home-screen widget for Chores Star. Shows a greeting, current streak,
//  up to three today's missions, and a pending-approval badge.
//

import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.hoque.hoqueFamilyChores"
private let maxMissions = 3

/// Data read from the shared App Group container written by the Flutter app.
struct WidgetData {
  let greeting: String
  let streakDays: Int
  let missionTitles: [String]
  let pendingApprovalCount: Int

  init(from defaults: UserDefaults?) {
    greeting = defaults?.string(forKey: "greeting") ?? "Hi there!"
    streakDays = defaults?.integer(forKey: "currentStreakDays") ?? 0
    let titles = defaults?.string(forKey: "missionTitles") ?? ""
    missionTitles = Array(titles.split(separator: "\n").map(String.init).prefix(maxMissions))
    pendingApprovalCount = defaults?.integer(forKey: "pendingApprovalCount") ?? 0
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(),
      greeting: "Hi there!",
      streakDays: 0,
      missionTitles: ["Make bed", "Tidy room"],
      pendingApprovalCount: 0
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let defaults = UserDefaults(suiteName: widgetGroupId)
    let data = WidgetData(from: defaults)
    let entry = SimpleEntry(
      date: Date(),
      greeting: data.greeting,
      streakDays: data.streakDays,
      missionTitles: Array(data.missionTitles),
      pendingApprovalCount: data.pendingApprovalCount
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      let timeline = Timeline(entries: [entry], policy: .atEnd)
      completion(timeline)
    }
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let greeting: String
  let streakDays: Int
  let missionTitles: [String]
  let pendingApprovalCount: Int
}

struct ChoresStarWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.greeting)
          .font(.system(size: 14, weight: .semibold))
          .lineLimit(1)

        Spacer()

        if entry.pendingApprovalCount > 0 {
          Text("\(entry.pendingApprovalCount)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(Color.red)
            .clipShape(Circle())
        }
      }

      if entry.missionTitles.isEmpty {
        Text("No missions today 🎉")
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .padding(.top, 2)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(entry.missionTitles, id: \.self) { title in
            HStack(alignment: .top, spacing: 4) {
              Text("•")
                .font(.system(size: 12))
              Text(title)
                .font(.system(size: 12))
                .lineLimit(1)
            }
          }
        }
        .padding(.top, 2)
      }

      Spacer()

      if entry.streakDays > 0 {
        Text("🔥 \(entry.streakDays)-day streak")
          .font(.system(size: 11))
          .foregroundColor(.orange)
      }
    }
    .padding(12)
    .widgetURL(URL(string: "hoquefamilychores://home"))
  }
}

@main
struct ChoresStarWidget: Widget {
  let kind: String = "ChoresStarWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      ChoresStarWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Chores Star")
    .description("See today's missions and streak at a glance.")
    .supportedFamilies([.systemSmall])
  }
}

struct ChoresStarWidget_Previews: PreviewProvider {
  static var previews: some View {
    ChoresStarWidgetEntryView(
      entry: SimpleEntry(
        date: Date(),
        greeting: "Hi Maya! 🔥 5-day streak",
        streakDays: 5,
        missionTitles: ["Make bed", "Tidy room", "Feed fish"],
        pendingApprovalCount: 1
      )
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
