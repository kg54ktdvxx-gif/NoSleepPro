//
//  AboutView.swift
//  AwakeApp
//
//  Clean, minimal About window with 3 tabs
//

import SwiftUI

struct AboutView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header with app icon and name
            VStack(spacing: 12) {
                // App icon from bundle
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                }

                Text("No Sleep Pro")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("Keep your Mac awake, effortlessly")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("About").tag(0)
                Text("Why No Sleep Pro").tag(1)
                Text("Tips & Tricks").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    AboutTabContent()
                case 1:
                    WhyAwakeAppTabContent()
                case 2:
                    TipsAndTricksTabContent()
                default:
                    AboutTabContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer
            VStack(spacing: 10) {
                Divider()

                Text("Made in Singapore")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
        }
        .frame(width: 460, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - About Tab Content

struct AboutTabContent: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                FeatureRow(icon: "moon.zzz.fill", title: "Prevents Sleep")
                FeatureRow(icon: "command", title: "Keyboard Shortcut")
                FeatureRow(icon: "app.badge", title: "App Triggers")
                FeatureRow(icon: "calendar", title: "Schedules")
                FeatureRow(icon: "battery.75percent", title: "Battery Protection")
                FeatureRow(icon: "bolt.fill", title: "Hardware Triggers")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - Why AwakeApp Tab Content

struct WhyAwakeAppTabContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                UseCaseRow(
                    icon: "video.fill",
                    title: "Presentations & Video Calls",
                    description: "Keep your display on during important meetings"
                )

                UseCaseRow(
                    icon: "arrow.down.circle.fill",
                    title: "Downloads & Uploads",
                    description: "Ensure large transfers complete without interruption"
                )

                UseCaseRow(
                    icon: "terminal.fill",
                    title: "Development & Builds",
                    description: "Keep your Mac awake during long builds"
                )

                UseCaseRow(
                    icon: "display.2",
                    title: "External Display Setup",
                    description: "Use your Mac with the lid closed"
                )

                UseCaseRow(
                    icon: "clock.fill",
                    title: "Work Hours Automation",
                    description: "Schedule active hours automatically"
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct UseCaseRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - Tips & Tricks Tab Content

struct TipsAndTricksTabContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TipRow(number: 1, tip: "Press ⌘⇧A anywhere to toggle instantly")
                TipRow(number: 2, tip: "Add apps like Zoom to auto-activate when running")
                TipRow(number: 3, tip: "Enable battery protection for automatic safety")
                TipRow(number: 4, tip: "Create schedules for your regular work hours")
                TipRow(number: 5, tip: "Show countdown in menu bar for quick glance")
                TipRow(number: 6, tip: "Use mouse jiggler to prevent 'Away' status")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct TipRow: View {
    let number: Int
    let tip: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                )

            Text(tip)
                .font(.system(size: 12))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

#Preview {
    AboutView()
}
