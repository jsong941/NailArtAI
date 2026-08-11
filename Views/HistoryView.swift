import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \HistorySession.createdAt, order: .reverse) private var sessions: [HistorySession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if sessions.isEmpty {
                EmptyHistoryView()
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: HistoryDetailView(session: session)) {
                            HistorySessionRow(session: session)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(sessions[index])
                        }
                    }

                    Text("History is kept for 7 days, then automatically removed.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 16, trailing: 24))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
            for session in sessions where session.createdAt < cutoff {
                modelContext.delete(session)
            }
        }
    }
}

// MARK: - Session Row

struct HistorySessionRow: View {
    let session: HistorySession

    var body: some View {
        HStack(spacing: 14) {
            // Color swatches
            HStack(spacing: -6) {
                ForEach(Array(session.colors.prefix(3).enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .zIndex(Double(3 - index))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.createdAt, format: .dateTime.month(.wide).day().year())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text("\(session.colors.count) colors extracted · \(session.createdAt, format: .dateTime.hour().minute())")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color.appAccent.opacity(0.5))

            Text("No History Yet")
                .font(.custom("CormorantGaramond-Bold", size: 24))
                .foregroundColor(Color.textPrimary)

            Text("Your past design sessions will\nappear here automatically.")
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Sessions are kept for 7 days.")
                .font(.system(size: 11))
                .foregroundColor(Color.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}
