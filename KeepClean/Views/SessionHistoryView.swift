import SwiftUI

// MARK: - Session History View (#10)

struct SessionHistoryView: View {
    let sessions: [StoredSession]
    let totalSessions: Int
    let totalLockSeconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sessions.isEmpty {
                emptyState
            } else {
                ForEach(Array(sessions.prefix(10).enumerated()), id: \.element.id) { idx, session in
                    sessionRow(session, index: idx)
                    if idx < min(sessions.count, 10) - 1 {
                        Divider().padding(.leading, 46)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(KeepCleanPalette.mutedInk)
            Text("No sessions yet")
                .font(KeepCleanType.caption)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
        .padding(.vertical, 8)
    }

    private func sessionRow(_ session: StoredSession, index: Int) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(session.mode == .keyboard
                          ? KeepCleanPalette.teal.opacity(0.12)
                          : KeepCleanPalette.orange.opacity(0.12))
                    .frame(width: 30, height: 30)

                Image(systemName: session.mode == .keyboard ? "keyboard" : "timer")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(session.mode == .keyboard
                                     ? KeepCleanPalette.teal
                                     : KeepCleanPalette.orange)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(session.mode == .keyboard ? "Keyboard Only" : "Full Clean")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(session.formattedDuration)
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }

            Spacer()

            Text(session.formattedDate)
                .font(KeepCleanType.caption)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.mode == .keyboard ? "Keyboard" : "Full") clean, \(session.formattedDuration), \(session.formattedDate)")
    }
}

// MARK: - Usage Stats Card (#21)

struct UsageStatsCard: View {
    let totalSessions: Int
    let totalLockSeconds: Int

    private var formattedTotal: String {
        let m = totalLockSeconds / 60
        let h = m / 60
        if h > 0 { return "\(h)h \(m % 60)m" }
        if m > 0 { return "\(m)m \(totalLockSeconds % 60)s" }
        return "\(totalLockSeconds)s"
    }

    var body: some View {
        HStack(spacing: 0) {
            statCell(value: "\(totalSessions)", label: "Sessions")
            Divider().frame(height: 36)
            statCell(value: formattedTotal, label: "Total Time")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(KeepCleanPalette.teal)
                .contentTransition(.numericText())  // #6 number flip
                .animation(.spring(response: 0.4), value: value)

            Text(label)
                .font(KeepCleanType.caption)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview (#30)

#Preview {
    let s0 = StoredSession(id: UUID(), mode: .keyboard, startedAt: Date().addingTimeInterval(-3600), durationSeconds: 60)
    let s1 = StoredSession(id: UUID(), mode: .timed,    startedAt: Date().addingTimeInterval(-7200), durationSeconds: 120)
    let s2 = StoredSession(id: UUID(), mode: .keyboard, startedAt: Date().addingTimeInterval(-10800), durationSeconds: 90)
    let sessions: [StoredSession] = [s0, s1, s2]
    return KeepCleanPanel {
        SessionHistoryView(sessions: sessions, totalSessions: 42, totalLockSeconds: 11520)
    }
    .padding()
    .frame(width: 480)
}
