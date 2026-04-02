import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \HistorySession.createdAt, order: .reverse) private var sessions: [HistorySession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8").ignoresSafeArea()

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
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
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
                    .font(.custom("CormorantGaramond-SemiBold", size: 16))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Text("\(session.designs.count) designs · \(session.createdAt, format: .dateTime.hour().minute())")
                    .font(.custom("CormorantGaramond-Italic", size: 13))
                    .foregroundColor(Color(hex: "8E8E93"))
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
                .foregroundColor(Color(hex: "C9A84C").opacity(0.5))

            Text("No History Yet")
                .font(.custom("CormorantGaramond-Bold", size: 24))
                .foregroundColor(Color(hex: "1C1C1E"))

            Text("Your past design sessions will\nappear here automatically.")
                .font(.custom("CormorantGaramond-Italic", size: 16))
                .foregroundColor(Color(hex: "8E8E93"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}
