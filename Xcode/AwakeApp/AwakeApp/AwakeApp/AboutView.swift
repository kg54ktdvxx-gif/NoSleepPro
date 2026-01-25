//
//  AboutView.swift
//  AwakeApp
//
//  Clean, simple about window for AwakeApp
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 10)

            // App icon
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.brown, Color.brown.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // App name
            Text("AwakeApp")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Version 1.2")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 40)

            // Description
            VStack(spacing: 8) {
                Text("Keep your Mac awake")
                    .font(.system(size: 14, weight: .medium))

                Text("Prevents sleep with smart automation,\nschedules, and battery protection.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Footer
            VStack(spacing: 12) {
                Text("Made with ❤️ & 🤖 in 🇸🇬")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }

            Spacer()
                .frame(height: 10)
        }
        .frame(width: 280, height: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    AboutView()
}
