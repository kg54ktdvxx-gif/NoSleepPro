//
//  MenuBarIcon.swift
//  AwakeApp
//
//  Customizable menu bar icon styles
//

import SwiftUI

/// Available menu bar icon styles
enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case coffeeCup = "cup.and.saucer"
    case moon = "moon.zzz"
    case bolt = "bolt"
    case eye = "eye"
    case sun = "sun.max"
    case battery = "battery.100.bolt"
    case clock = "clock"
    case power = "power"

    var id: String { rawValue }

    /// SF Symbol name for inactive state
    var systemName: String { rawValue }

    /// SF Symbol name for active state (filled version)
    var filledSystemName: String {
        switch self {
        case .coffeeCup: return "cup.and.saucer.fill"
        case .moon: return "moon.zzz.fill"
        case .bolt: return "bolt.fill"
        case .eye: return "eye.fill"
        case .sun: return "sun.max.fill"
        case .battery: return "battery.100.bolt"
        case .clock: return "clock.fill"
        case .power: return "power.circle.fill"
        }
    }

    /// Human-readable name
    var displayName: String {
        switch self {
        case .coffeeCup: return "Coffee Cup"
        case .moon: return "Moon"
        case .bolt: return "Lightning Bolt"
        case .eye: return "Eye"
        case .sun: return "Sun"
        case .battery: return "Battery"
        case .clock: return "Clock"
        case .power: return "Power"
        }
    }

    /// Preview view for icon picker
    @ViewBuilder
    func previewIcon(isActive: Bool) -> some View {
        Image(systemName: isActive ? filledSystemName : systemName)
            .symbolRenderingMode(.hierarchical)
    }
}

/// Menu bar icon view that respects user's style preference
struct MenuBarIconView: View {
    let style: MenuBarIconStyle
    let isActive: Bool
    let showCountdown: Bool
    let remainingTime: String?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? style.filledSystemName : style.systemName)
                .symbolRenderingMode(.hierarchical)

            if showCountdown, let time = remainingTime {
                Text(time)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedStyle: MenuBarIconStyle
    @Environment(\.dismiss) var dismiss

    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Icon Style")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MenuBarIconStyle.allCases) { style in
                    IconOptionView(
                        style: style,
                        isSelected: selectedStyle == style,
                        onSelect: {
                            selectedStyle = style
                            dismiss()
                        }
                    )
                }
            }
            .padding()

            Text("Preview shows active state")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 350, height: 300)
    }
}

struct IconOptionView: View {
    let style: MenuBarIconStyle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Show both inactive and active states
                HStack(spacing: 12) {
                    Image(systemName: style.systemName)
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Image(systemName: style.filledSystemName)
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }

                Text(style.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 90, height: 70)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IconPickerView(selectedStyle: .constant(.coffeeCup))
}
