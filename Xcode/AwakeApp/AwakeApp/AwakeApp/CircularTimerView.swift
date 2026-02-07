//
//  CircularTimerView.swift
//  AwakeApp
//
//  Circular progress timer display with gradient stroke
//

import SwiftUI

struct CircularTimerView: View {
    let remainingSeconds: Int
    let totalSeconds: Int

    private var progress: Double {
        guard totalSeconds > 0 else { return 1.0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private var formattedTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.awakeBlue,
                            Color.awakeBlue.opacity(0.8),
                            Color.awakePurple.opacity(0.6),
                            Color.awakeBlue
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)

                // Percentage badge
                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.awakeBlue)
                    )
            }
        }
        .frame(width: 100, height: 100)
    }
}

// MARK: - Compact Circular Timer (for menu bar)

struct CompactCircularTimerView: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let size: CGFloat

    init(remainingSeconds: Int, totalSeconds: Int, size: CGFloat = 60) {
        self.remainingSeconds = remainingSeconds
        self.totalSeconds = totalSeconds
        self.size = size
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 1.0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    private var formattedTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.awakeBlue, Color.awakeBlue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)

            // Time display
            Text(formattedTime)
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Indefinite Timer View

struct IndefiniteTimerView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Pulsing background
            Circle()
                .fill(Color.awakeBlue.opacity(0.1))
                .frame(width: 100, height: 100)

            // Rotating gradient ring
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.awakeBlue.opacity(0.1),
                            Color.awakeBlue,
                            Color.awakeBlue.opacity(0.1)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 84, height: 84)
                .rotationEffect(.degrees(rotation))

            // Center content
            VStack(spacing: 4) {
                Image(systemName: "infinity")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.awakeBlue)

                Text("Running")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, height: 100)
        .onAppear {
            withAnimation(
                .linear(duration: 3.0)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview("Circular Timer") {
    VStack(spacing: 30) {
        CircularTimerView(remainingSeconds: 2700, totalSeconds: 3600)
        CircularTimerView(remainingSeconds: 900, totalSeconds: 3600)
        CompactCircularTimerView(remainingSeconds: 1800, totalSeconds: 3600)
        IndefiniteTimerView()
    }
    .padding()
    .background(Color(nsColor: .windowBackgroundColor))
}
