//
//  ThemeSectionView.swift
//  ChessApp
//
//  Theme color picker section for Settings
//

import SwiftUI

struct ThemeSectionView: View {
    @Environment(AppTheme.self) private var theme
    @State private var tempColor = Color.blue

    var body: some View {
        NavigationStack {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Theme Color")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 12)], spacing: 12) {
                        ForEach(AppTheme.availableColors, id: \.name) { colorOption in
                            ColorOptionView(
                                color: colorOption.color,
                                name: colorOption.name,
                                isSelected: theme.primaryColor == colorOption.color,
                                onSelect: { theme.primaryColor = colorOption.color }
                            )
                        }

                        // Custom Color Picker Button
                        CustomColorButtonView(
                            tempColor: $tempColor,
                            onColorPicked: { finalColor in
                                theme.primaryColor = finalColor
                            }
                        )
                    }
                }
            } header: {
                Label("Appearance", systemImage: "paintpalette")
            } footer: {
                Text("Choose your preferred app theme color or pick a custom color.")
            }
        }
    }
}

// MARK: - Color Option Component

struct ColorOptionView: View {
    let color: Color
    let name: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
                .frame(height: 60)
                .onTapGesture(perform: onSelect)

            Text(name)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

// MARK: - Custom Color Button Component

struct CustomColorButtonView: View {
    @Binding var tempColor: Color
    let onColorPicked: (Color) -> Void

    var body: some View {
        VStack {
            NavigationLink(
                destination: ColorPickerView(color: $tempColor, onConfirm: onColorPicked),
                label: {
                    ZStack {
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(Color.gray.opacity(0.3))

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            )
            .frame(height: 60)

            Text("Custom")
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

// MARK: - Custom Color Picker View

struct ColorPickerView: View {
    @Binding var color: Color
    @Environment(\.dismiss) var dismiss
    let onConfirm: (Color) -> Void

    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1

    var body: some View {
        VStack(spacing: 20) {
            // Color Preview
            Circle()
                .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                .frame(height: 120)
                .padding()

            VStack(alignment: .leading, spacing: 16) {
                // Hue Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hue: hue, saturation: 1, brightness: 1))
                            .frame(width: 24, height: 24)

                        Text("Hue")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HueSliderView(value: $hue)
                }

                // Saturation Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hue: hue, saturation: saturation, brightness: 1))
                            .frame(width: 24, height: 24)

                        Text("Saturation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    SaturationSliderView(value: $saturation, hue: hue)
                }

                // Brightness Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                            .frame(width: 24, height: 24)

                        Text("Brightness")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    BrightnessSliderView(value: $brightness, hue: hue, saturation: saturation)
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)

                Button("Done") {
                    let finalColor = Color(hue: hue, saturation: saturation, brightness: brightness)
                    color = finalColor
                    onConfirm(finalColor)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Custom Color")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize sliders from the current color
            let uiColor = UIColor(color)
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
            hue = Double(h)
            saturation = Double(s)
            brightness = Double(b)
        }
    }
}

// MARK: - Custom Slider Views

struct HueSliderView: View {
    @Binding var value: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: (0..<10).map { i in
                    Color(hue: Double(i) / 10, saturation: 1, brightness: 1)
                }),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 6)
            .cornerRadius(3)

            // Slider on top
            Slider(value: $value, in: 0...1)
                .tint(.clear)
        }
    }
}

struct SaturationSliderView: View {
    @Binding var value: Double
    let hue: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Gradient from desaturated to saturated
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hue: hue, saturation: 0, brightness: 1),
                    Color(hue: hue, saturation: 1, brightness: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 6)
            .cornerRadius(3)

            // Slider on top
            Slider(value: $value, in: 0...1)
                .tint(.clear)
        }
    }
}

struct BrightnessSliderView: View {
    @Binding var value: Double
    let hue: Double
    let saturation: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Gradient from dark to bright
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hue: hue, saturation: saturation, brightness: 0),
                    Color(hue: hue, saturation: saturation, brightness: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 6)
            .cornerRadius(3)

            // Slider on top
            Slider(value: $value, in: 0...1)
                .tint(.clear)
        }
    }
}

#Preview {
    Form {
        ThemeSectionView()
            .environment(AppTheme.shared)
    }
}
