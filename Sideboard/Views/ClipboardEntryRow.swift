import SwiftUI

struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    let actions: [ClipboardEntryAction]

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.preview)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    if let sourceApp = entry.sourceApp {
                        Text(sourceApp)
                    }
                    Text(entry.timestamp, style: .time)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                ForEach(actions) { action in
                    Button {
                        action.handler()
                    } label: {
                        Image(systemName: action.systemImage)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(action.role == .destructive ? Color.red : .secondary)
                    .help(action.help)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color.accentColor.opacity(0.1) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

struct ClipboardEntryAction: Identifiable {
    enum Role {
        case normal
        case destructive
    }

    var id: String { systemImage + help }
    let systemImage: String
    let help: String
    let role: Role
    let handler: () -> Void
}
