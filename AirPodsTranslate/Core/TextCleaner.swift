import Foundation

/// 识别结果清洗：去空白、去语气词、去 Whisper 常见幻觉短句、折叠重复。
enum TextCleaner {
    private static let fillers = ["嗯嗯", "嗯", "呃", "啊", "呀", "哦", "那个", "就是"]

    private static let hallucinations = [
        "字幕提供：众娱",
        "请不吝点赞 订阅 转发 打赏支持明镜与点点栏目",
        "Thank you for watching.",
        "Thanks for watching!",
        "Subtitles by the Amara.org community"
    ]

    static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        for h in hallucinations where text == h {
            return ""
        }

        // 折叠多余空白
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // 纯语气词整句丢弃
        let stripped = fillers.reduce(text) { partial, filler in
            partial.replacingOccurrences(of: filler, with: "")
        }
        if stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ""
        }

        return text
    }
}

/// 术语库后处理：模型未译出的专有名词按用户指定写法替换。
enum GlossaryApplier {
    static func apply(translated: String, entries: [GlossaryEntry]) -> String {
        var result = translated
        for entry in entries {
            guard !entry.source.isEmpty, !entry.replacement.isEmpty else { continue }
            result = result.replacingOccurrences(
                of: entry.source,
                with: entry.replacement,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }
        return result
    }
}
