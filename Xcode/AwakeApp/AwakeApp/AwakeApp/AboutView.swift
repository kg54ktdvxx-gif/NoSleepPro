//
//  AboutView.swift
//  AwakeApp
//
//  Modern, professional about window for AwakeApp
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.88, blue: 0.76).opacity(0.3),
                    Color(red: 0.85, green: 0.75, blue: 0.65).opacity(0.2),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 40)

                    // App name with gradient text
                    Text("AwakeApp")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Version 1.2")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, -12)

                    Spacer()
                        .frame(height: 20)
                }

                // Feature highlights
                VStack(spacing: 16) {
                    FeatureRow(icon: "cup.and.saucer.fill", title: "Prevents Sleep", description: "Keep your Mac awake and productive")
                    FeatureRow(icon: "keyboard", title: "Keyboard Shortcut", description: "Toggle with ⌘⇧A anywhere")
                    FeatureRow(icon: "app.badge", title: "App Triggers", description: "Auto-activate for Zoom, PowerPoint, etc.")
                    FeatureRow(icon: "calendar", title: "Schedules", description: "Stay awake during work hours")
                    FeatureRow(icon: "battery.50", title: "Battery Protection", description: "Auto-stop when battery is low")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 24)

                // Links section
                HStack(spacing: 24) {
                    LinkButton(title: "Website", icon: "globe", url: "https://awakeapp.com")
                    LinkButton(title: "Support", icon: "questionmark.circle", url: "https://awakeapp.com/support")
                    LinkButton(title: "Privacy", icon: "hand.raised", url: "https://awakeapp.com/privacy")
                }
                .padding(.vertical, 16)

                Spacer()

                // Footer with credits and close button
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 40)

                    Text("Built with ❤️ & 🤖 in 🇸🇬")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Button(action: {
                        NSApp.keyWindow?.close()
                    }) {
                        Text("Close")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 36)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)

                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .frame(width: 480, height: 520)
    }
}

// Feature row component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// Link button component
struct LinkButton: View {
    let title: String
    let icon: String
    let url: String
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isHovering ? .blue : .secondary)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isHovering ? .blue : .secondary)
            }
            .frame(width: 70, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    AboutView()
}
