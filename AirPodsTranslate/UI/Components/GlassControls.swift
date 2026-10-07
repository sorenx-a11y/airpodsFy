import SwiftUI

// MARK: - 玻璃底部选择器（对齐 HTML 原型的 sheet）

struct GlassOption<T: Hashable>: Identifiable {
    let id = UUID()
    let value: T
    let label: String
}

struct GlassOptionSheet<T: Hashable>: View {
    let title: String
    let options: [GlassOption<T>]
    @Binding var selection: T
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.top, 6)

            VStack(spacing: 0) {
                ForEach(options) { opt in
                    Button {
                        selection = opt.value
                        dismiss()
                    } label: {
                        HStack {
                            Text(opt.label)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection == opt.value {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.brand)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 15)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if opt.id != options.last?.id {
                        Divider()
                            .overlay(Color.primary.opacity(0.08))
                            .padding(.leading, 18)
                    }
                }
            }
            .glassCard(cornerRadius: 18)
            .padding(.horizontal, 8)

            Button {
                dismiss()
            } label: {
                Text("取消")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.brand)
            .glassCard(cornerRadius: 18)
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .presentationDetents([.height(CGFloat(options.count * 54 + 150)), .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 设置分组

struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .glassCard(cornerRadius: 18)
        .padding(.horizontal, 16)
    }
}

struct GroupTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

/// 设置行：图标 + 标题 + 右侧内容
struct SettingsRow<Accessory: View>: View {
    var icon: String?
    var title: String
    var titleColor: Color = .primary
    var showChevron: Bool = false
    var action: (() -> Void)?
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        let row = HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(titleColor == .primary ? Color.brand : titleColor)
                    .frame(width: 22)
            }
            Text(title)
                .font(.system(size: 14.5))
                .foregroundStyle(titleColor)
            Spacer(minLength: 8)
            accessory()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())

        Group {
            if let action {
                Button(action: action) { row }.buttonStyle(.plain)
            } else {
                row
            }
        }
    }
}

/// 分组内的分隔线
struct RowDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.primary.opacity(0.08))
            .padding(.leading, 48)
    }
}

/// 说明小字行
struct SettingsNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11.5))
            .foregroundStyle(.secondary)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}
