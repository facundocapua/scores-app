import SwiftUI

/// The Generala Scoresheet (SPEC §5.3, §8, `DESIGN.md`): categories in rows, Players in
/// columns, the one rolling highlighted with "Tira". It scales with Dynamic Type up to
/// xxxLarge; from AX1 the category column stays fixed and the Player columns scroll
/// horizontally. It also scrolls horizontally whenever the columns don't fit.
struct GeneralaScoresheet: View {
    var names: [String]
    var entries: [Generala.Entry]
    var variant: Generala.Variant
    var turn: Int?
    /// Called with the Player and the category of a tapped cell. `nil` makes it read-only.
    var onSelect: ((Int, Generala.Category) -> Void)?

    @Environment(\.dynamicTypeSize) private var systemTypeSize

    var body: some View {
        ScrollView(.vertical) {
            SheetGrid(
                names: names,
                entries: entries,
                variant: variant,
                turn: turn,
                forcesScroll: systemTypeSize.isAccessibilitySize,
                onSelect: onSelect
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The Scoresheet's text stops growing at xxxLarge (SPEC §8).
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct SheetGrid: View {
    var names: [String]
    var entries: [Generala.Entry]
    var variant: Generala.Variant
    var turn: Int?
    var forcesScroll: Bool
    var onSelect: ((Int, Generala.Category) -> Void)?

    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 46
    @ScaledMetric(relativeTo: .body) private var headerHeight: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var totalHeight: CGFloat = 56
    @ScaledMetric(relativeTo: .body) private var categoryWidth: CGFloat = 100
    @ScaledMetric(relativeTo: .body) private var minColumnWidth: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var scrollColumnWidth: CGFloat = 72
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let categories = Generala.Category.allCases
    @State private var gridWidth: CGFloat = 0

    /// Whether every Player column gets its minimum width without scrolling.
    private var fits: Bool {
        gridWidth == 0 || (gridWidth - categoryWidth - 1) / CGFloat(max(names.count, 1)) >= minColumnWidth
    }

    var body: some View {
        HStack(spacing: 0) {
            categoryColumn
                .frame(width: categoryWidth)
            Rectangle()
                .fill(GeneralaWorld.brass.opacity(0.35))
                .frame(width: 1)
            players
        }
        .foregroundStyle(GeneralaWorld.ink)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { gridWidth = $0 }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(GeneralaWorld.brass.opacity(0.7), lineWidth: 1.5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(GeneralaWorld.brass.opacity(0.3), lineWidth: 1)
                .padding(4)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Layout

    @ViewBuilder private var players: some View {
        if forcesScroll {
            scrollingPlayers
        } else {
            if fits {
                HStack(spacing: 0) {
                    ForEach(names.indices, id: \.self) { column($0, width: nil) }
                }
            } else {
                scrollingPlayers
            }
        }
    }

    private var scrollingPlayers: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(names.indices, id: \.self) { column($0, width: scrollColumnWidth).id($0) }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: turn) { _, turn in
                guard let turn else { return }
                withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.3)) {
                    proxy.scrollTo(turn, anchor: .center)
                }
            }
        }
    }

    // MARK: - Category column

    private var categoryColumn: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: headerHeight)
                .overlay(alignment: .bottom) { rule(heavy: true) }
            ForEach(categories, id: \.self) { category in
                categoryLabel(category)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                    .frame(height: rowHeight)
                    .overlay(alignment: .bottom) { rule(heavy: category == .sixes) }
            }
            Text("Total")
                .font(DisplayFont.abrilFatface.scaled(18, relativeTo: .headline))
                .foregroundStyle(GeneralaWorld.brass)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                .frame(height: totalHeight)
        }
    }

    @ViewBuilder private func categoryLabel(_ category: Generala.Category) -> some View {
        if let face = category.face {
            Image(systemName: "die.face.\(face)")
                .font(.title3)
                .accessibilityLabel(category.title)
        } else {
            Text(category.shortTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityLabel(category.title)
        }
    }

    // MARK: - Player columns

    private func column(_ index: Int, width: CGFloat?) -> some View {
        let isTurn = turn == index
        return VStack(spacing: 0) {
            header(index, isTurn: isTurn)
                .frame(height: headerHeight)
                .overlay(alignment: .bottom) { rule(heavy: true) }
            ForEach(categories, id: \.self) { category in
                cell(index, category)
                    .frame(height: rowHeight)
                    .overlay(alignment: .bottom) { rule(heavy: category == .sixes) }
            }
            Text("\(Generala.total(of: index, in: entries))")
                .font(DisplayFont.abrilFatface.scaled(22, relativeTo: .title3))
                .monospacedDigit()
                .foregroundStyle(GeneralaWorld.brass)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: totalHeight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(names[index]), total, \(Generala.total(of: index, in: entries))")
        }
        .frame(width: width)
        .frame(minWidth: minColumnWidth, maxWidth: width == nil ? .infinity : nil)
        .background(isTurn ? GeneralaWorld.brass.opacity(0.14) : .clear)
        .overlay(alignment: .leading) {
            if index > 0 {
                Rectangle().fill(GeneralaWorld.brass.opacity(0.12)).frame(width: 1)
            }
        }
    }

    private func header(_ index: Int, isTurn: Bool) -> some View {
        VStack(spacing: 3) {
            Text("Tira")
                .font(.caption2.weight(.heavy))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(GeneralaWorld.feltDark)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(GeneralaWorld.brass, in: Capsule())
                .opacity(isTurn ? 1 : 0)
                .accessibilityHidden(true)
            Text(names[index])
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isTurn ? "\(names[index]), tira" : names[index])
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private func cell(_ participant: Int, _ category: Generala.Category) -> some View {
        let entry = Generala.entry(of: participant, category, in: entries)
        let content = cellContent(entry)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Generala.Entry.spoken(name: names[participant], category: category, entry: entry))
        if let onSelect {
            Button { onSelect(participant, category) } label: { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    @ViewBuilder private func cellContent(_ entry: Generala.Entry?) -> some View {
        switch entry?.mark {
        case nil:
            Circle()
                .fill(GeneralaWorld.ink.opacity(0.22))
                .frame(width: 6, height: 6)
        case .scratched?:
            // A mark in the text color, so it doesn't depend on color alone.
            Text("✕")
                .font(.system(.title3, design: .rounded).weight(.semibold))
        case .points(let points)?:
            HStack(alignment: .top, spacing: 1) {
                Text("\(points)")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                if entry?.served == true {
                    Text("S")
                        .font(.caption2.weight(.heavy))
                        .padding(.top, 2)
                }
            }
        }
    }

    private func rule(heavy: Bool) -> some View {
        Rectangle()
            .fill(GeneralaWorld.brass.opacity(heavy ? 0.6 : 0.18))
            .frame(height: heavy ? 1.5 : 1)
    }
}

#Preview("Six Players") {
    let names = ["Ana", "Beto", "Caro", "Facundo", "Lu", "Martín"]
    let entries: [Generala.Entry] = [
        .init(participant: 0, category: .sixes, mark: .points(24)),
        .init(participant: 0, category: .fullHouse, mark: .points(35), served: true),
        .init(participant: 1, category: .straight, mark: .scratched),
        .init(participant: 2, category: .generala, mark: .points(50)),
        .init(participant: 3, category: .fourOfAKind, mark: .points(40)),
    ]
    return GeneralaScoresheet(names: names, entries: entries, variant: .standard, turn: 1, onSelect: { _, _ in })
        .background(GeneralaWorld.background)
}
