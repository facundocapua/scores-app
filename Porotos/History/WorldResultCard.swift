import SwiftUI

/// The colors and type of a Game's world, for the result card of the History detail.
struct ResultStyle {
    var background: AnyShapeStyle
    var ink: Color
    var dim: Color
    var highlight: Color
    var headlineFont: Font
    var nameFont: Font
}

/// The result of a Finished Match in its Game's world (SPEC §5.5): the Winners (or "Empate"),
/// "Terminada antes" if it applies, and everyone's score with its position, where shared
/// positions repeat "1.º". Each Game supplies the headline, its style and how a score is drawn.
struct WorldResultCard<Score: View, Extra: View>: View {
    var entry: HistoryEntry
    var headline: String
    var style: ResultStyle
    @ViewBuilder var score: (Int) -> Score
    @ViewBuilder var extra: () -> Extra

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(headline)
                    .font(style.headlineFont)
                    .foregroundStyle(style.highlight)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                if entry.isTie {
                    Text(entry.winnersText)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                if entry.endedEarly {
                    Text("Terminada antes")
                        .font(.subheadline)
                        .foregroundStyle(style.dim)
                }
            }
            VStack(spacing: 0) {
                ForEach(entry.ranking) { participant in
                    row(participant)
                }
            }
            extra()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .foregroundStyle(style.ink)
        .background(style.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private func row(_ participant: HistoryEntry.Participant) -> some View {
        HStack(spacing: 12) {
            if entry.participants.count > 2 {
                Text(Outcome.ordinal(participant.position))
                    .font(.headline)
                    .foregroundStyle(participant.isWinner ? style.highlight : style.dim)
                    .frame(minWidth: 40, alignment: .leading)
            }
            Text(participant.name)
                .font(style.nameFont)
                .foregroundStyle(participant.isWinner ? style.highlight : style.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            score(participant.score)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            (entry.participants.count > 2 ? "\(Outcome.ordinal(participant.position)), " : "") + participant.name
        )
        .accessibilityValue("\(participant.score)" + (participant.isWinner ? ", ganó" : ""))
    }
}

extension WorldResultCard where Extra == EmptyView {
    init(
        entry: HistoryEntry,
        headline: String,
        style: ResultStyle,
        @ViewBuilder score: @escaping (Int) -> Score
    ) {
        self.init(entry: entry, headline: headline, style: style, score: score, extra: { EmptyView() })
    }
}
