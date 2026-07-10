import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var cursorModel: CursorModel

    var body: some View {
        HStack(spacing: 0) {
            previewPane
            Divider()
            controlsPane
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: [.gif, .image], isTargeted: nil) { providers in
            cursorModel.handleDrop(providers)
        }
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Lang.appName(cursorModel.language))
                    .font(.system(size: 34, weight: .semibold))
                Text(Lang.appSubtitle(cursorModel.language))
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                CursorPreviewView()
                    .environmentObject(cursorModel)
            }
            .aspectRatio(1, contentMode: .fit)

            statusBar
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var controlsPane: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 22) {
                Button {
                    cursorModel.pickGIF()
                } label: {
                    Label(Lang.chooseGIF(cursorModel.language), systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 10) {
                    Text(Lang.cursorSize(cursorModel.language))
                        .font(.headline)
                    CursorSizeSlider(value: $cursorModel.cursorSize, range: 24...160)
                    Text("\(Int(cursorModel.cursorSize)) px")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(Lang.hotSpot(cursorModel.language))
                        .font(.headline)
                    Picker(Lang.hotSpot(cursorModel.language), selection: $cursorModel.hotSpotPreset) {
                        ForEach(HotSpotPreset.allCases) { preset in
                            Text(preset.title(language: cursorModel.language)).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle(isOn: $cursorModel.isCursorEnabled) {
                    Label(Lang.enableCustomCursor(cursorModel.language), systemImage: cursorModel.isCursorEnabled ? "cursorarrow.motionlines" : "cursorarrow")
                }
                .toggleStyle(.switch)
                .disabled(cursorModel.frames.isEmpty)

                Toggle(isOn: $cursorModel.shouldHideSystemCursor) {
                    Label(Lang.hideSystemCursor(cursorModel.language), systemImage: cursorModel.shouldHideSystemCursor ? "eye.slash" : "eye")
                }
                .toggleStyle(.switch)
                .disabled(!cursorModel.isCursorEnabled)

                Button(role: .destructive) {
                    cursorModel.reset()
                } label: {
                    Label(Lang.reset(cursorModel.language), systemImage: "arrow.counterclockwise")
                }
                .disabled(cursorModel.frames.isEmpty)

                Text(Lang.systemCursorNote(cursorModel.language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Text(Lang.language(cursorModel.language))
                        .font(.headline)
                    Picker(Lang.language(cursorModel.language), selection: $cursorModel.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label(Lang.quit(cursorModel.language), systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: cursorModel.frames.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                .foregroundStyle(cursorModel.frames.isEmpty ? Color.secondary : Color.green)
            Text(cursorModel.statusText)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.callout)
    }
}

struct CursorSizeSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>

    private let thumbSize: CGFloat = 18
    private let trackHeight: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(1, geometry.size.width - thumbSize)
            let progress = normalizedProgress
            let thumbX = progress * availableWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(nsColor: .separatorColor).opacity(0.45))
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: thumbX + thumbSize / 2, height: trackHeight)
                    .padding(.leading, thumbSize / 2)

                Circle()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .offset(x: thumbX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(from: gesture.location.x, width: availableWidth)
                    }
            )
        }
        .frame(height: 22)
    }

    private var normalizedProgress: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return ((value - range.lowerBound) / span).clamped(to: 0...1)
    }

    private func updateValue(from xPosition: CGFloat, width: CGFloat) {
        let progress = ((xPosition - thumbSize / 2) / width).clamped(to: 0...1)
        let rawValue = range.lowerBound + progress * (range.upperBound - range.lowerBound)
        value = rawValue.rounded()
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

struct CursorPreviewView: View {
    @EnvironmentObject private var cursorModel: CursorModel

    var body: some View {
        ZStack {
            GridPattern()
                .stroke(.secondary.opacity(0.18), lineWidth: 1)

            if let image = cursorModel.currentImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cursorModel.cursorSize, height: cursorModel.cursorSize)
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                    Text(Lang.dropGIFHint(cursorModel.language))
                        .font(.headline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(28)
    }
}

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 24

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}
