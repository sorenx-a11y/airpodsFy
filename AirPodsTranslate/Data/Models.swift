import Foundation
import SwiftData

enum Speaker: String, Codable {
    case me         // 我方
    case them       // 对方
}

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var myLanguageCode: String
    var theirLanguageCode: String

    @Relationship(deleteRule: .cascade, inverse: \MessageEntity.conversation)
    var messages: [MessageEntity] = []

    init(title: String = "新对话",
         myLanguageCode: String,
         theirLanguageCode: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.myLanguageCode = myLanguageCode
        self.theirLanguageCode = theirLanguageCode
    }
}

@Model
final class MessageEntity {
    @Attribute(.unique) var id: UUID
    var speakerRaw: String
    var sourceText: String
    var translatedText: String
    var sourceLanguageCode: String
    var targetLanguageCode: String
    var createdAt: Date
    var conversation: Conversation?

    var speaker: Speaker {
        get { Speaker(rawValue: speakerRaw) ?? .me }
        set { speakerRaw = newValue.rawValue }
    }

    init(speaker: Speaker,
         sourceText: String,
         translatedText: String,
         sourceLanguageCode: String,
         targetLanguageCode: String) {
        self.id = UUID()
        self.speakerRaw = speaker.rawValue
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguageCode = sourceLanguageCode
        self.targetLanguageCode = targetLanguageCode
        self.createdAt = Date()
    }
}

@Model
final class GlossaryEntry {
    @Attribute(.unique) var id: UUID
    /// 源词（说出口时可能出现的写法）
    var source: String
    /// 译文里必须使用的写法
    var replacement: String
    var languagePairKey: String   // 例如 zh-Hans -> en
    var createdAt: Date

    init(source: String, replacement: String, pairKey: String) {
        self.id = UUID()
        self.source = source
        self.replacement = replacement
        self.languagePairKey = pairKey
        self.createdAt = Date()
    }
}
