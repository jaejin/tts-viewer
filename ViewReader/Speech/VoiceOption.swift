import AVFoundation

/// 목소리 선택 화면에 보여줄 음성 정보
struct VoiceOption: Identifiable, Equatable, Sendable {
    enum Quality: Int, Comparable, Sendable {
        case standard = 0
        case enhanced = 1
        case premium = 2

        var label: String {
            switch self {
            case .standard: "기본"
            case .enhanced: "고품질"
            case .premium: "프리미엄"
            }
        }

        static func < (lhs: Quality, rhs: Quality) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let id: String
    let name: String
    let quality: Quality

    init(id: String, name: String, quality: Quality) {
        self.id = id
        self.name = name
        self.quality = quality
    }

    init(voice: AVSpeechSynthesisVoice) {
        let quality: Quality = switch voice.quality {
        case .premium: .premium
        case .enhanced: .enhanced
        default: .standard
        }
        self.init(id: voice.identifier, name: voice.name, quality: quality)
    }

    /// 좋은 음성을 먼저 고르도록 품질 높은 순, 같은 품질은 이름 순으로 정렬한다
    static func sorted(_ options: [VoiceOption]) -> [VoiceOption] {
        options.sorted {
            if $0.quality != $1.quality {
                return $0.quality > $1.quality
            }
            return $0.name < $1.name
        }
    }
}
