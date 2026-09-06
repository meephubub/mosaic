import SwiftUI

/// The mascot's mood; drives subtle, premium animation states.
enum BotMood: Equatable {
    case idle
    case alert
    case thinking
    case happy
    case confused
}

/// The bot: black circular body, two white eyes, no mouth. Pure SwiftUI so it
/// can animate fluidly at any size. Keep it subtle — a companion, not a toy.
struct BotView: View {
    var mood: BotMood = .idle
    var size: CGFloat = 34
    var eyeOffset: CGSize = .zero

    @State private var bobbing = false
    @State private var blink = false
    @State private var wanderPhase: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            HStack(spacing: size * 0.16) {
                eye
                eye
            }
            .offset(x: eyeOffset.width * size * 0.06, y: eyeOffset.height * size * 0.06)
        }
        .offset(y: bobbing ? -2.5 : 1.5)
        .scaleEffect(mood == .confused ? 0.94 : 1)
        .onAppear { startLoops() }
        .onTapGesture { blinkOnce() }
        .accessibilityLabel("Mosaic assistant bot")
    }

    private var eye: some View {
        Circle()
            .fill(Color.white)
            .frame(width: eyeSize, height: eyeSize)
            .scaleEffect(x: blink ? 0.12 : 1, y: blink ? 0.1 : 1, anchor: .center)
            .animation(blink ? .easeInOut(duration: 0.09) : nil, value: blink)
            .offset(eyeWander)
    }

    private var eyeSize: CGFloat { max(3.5, size * 0.14) }

    private var eyeWander: CGSize {
        switch mood {
        case .thinking:
            return CGSize(width: wanderPhase == 0 ? 1.5 : -1.5, height: 1)
        case .alert:
            return CGSize(width: 0, height: -0.8)
        case .happy:
            return CGSize(width: 0, height: -0.5)
        case .confused:
            return CGSize(width: -1.5, height: 0.5)
        case .idle:
            return .zero
        }
    }

    private func startLoops() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            bobbing = true
        }
        scheduleBlink()
        if mood == .thinking {
            scheduleWander()
        }
    }

    private func scheduleBlink() {
        Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.4...5.2)))
            guard !Task.isCancelled else { return }
            blinkOnce()
            scheduleBlink()
        }
    }

    private func blinkOnce() {
        withAnimation(.easeInOut(duration: 0.09)) { blink = true }
        Task {
            try? await Task.sleep(for: .milliseconds(130))
            withAnimation(.easeInOut(duration: 0.09)) { blink = false }
        }
    }

    private func scheduleWander() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.easeInOut(duration: 0.7)) {
                    wanderPhase = (wanderPhase + 1) % 2
                }
            }
        }
    }
}
