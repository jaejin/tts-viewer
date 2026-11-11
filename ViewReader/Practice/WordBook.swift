import CoreGraphics
import Foundation
import Observation

/// 아이가 책에서 찍어 모은 낱말. 앱을 다시 켜도 남도록 파일에 저장한다.
/// 낱말을 찍은 사진도 함께 보관해, 어느 문장에서 나온 낱말인지 다시 볼 수 있게 한다.
@MainActor
@Observable
final class WordBook {
    struct Entry: Codable, Identifiable, Hashable {
        let id: UUID
        let text: String
        let savedAt: Date
        /// 찍은 사진 파일 이름. 사진 저장 기능 전에 모은 낱말은 없다
        var imageFileName: String?
        /// 사진 안에서 낱말 위치 (좌상단 원점 0~1)
        var wordFrame: CGRect?
    }

    struct NewWord: Equatable {
        let text: String
        var frame: CGRect?
    }

    /// 너무 많이 쌓이면 아이가 목록에서 길을 잃으므로 오래된 낱말부터 정리한다
    static let maximumCount = 100

    private(set) var entries: [Entry] = []
    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let imagesDirectory: URL

    init(fileURL: URL = WordBook.defaultFileURL) {
        self.fileURL = fileURL
        imagesDirectory = fileURL.deletingLastPathComponent().appending(path: "wordbook-images")
        entries = Self.load(from: fileURL)
    }

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "wordbook.json")
    }

    func imageURL(for entry: Entry) -> URL? {
        entry.imageFileName.map { imagesDirectory.appending(path: $0) }
    }

    @discardableResult
    func add(_ texts: [String], now: Date = .now) -> Int {
        add(texts.map { NewWord(text: $0) }, now: now)
    }

    /// - Parameter imageData: 낱말을 찍은 사진(JPEG). 한 번 찍어 고른 낱말들은 사진 한 장을 함께 쓴다
    /// - Returns: 실제로 들어간 낱말 수 (빈 낱말 제외, 중복은 맨 앞으로 옮기며 1개로 센다)
    @discardableResult
    func add(_ words: [NewWord], imageData: Data? = nil, now: Date = .now) -> Int {
        var seen = Set<String>()
        let unique = words.compactMap { word -> NewWord? in
            let text = Hangul.cleanWord(word.text)
            guard !text.isEmpty, seen.insert(text).inserted else { return nil }
            return NewWord(text: text, frame: word.frame)
        }
        guard !unique.isEmpty else { return 0 }

        let imageFileName = imageData.flatMap(saveImage)
        let newEntries = unique.map {
            Entry(id: UUID(), text: $0.text, savedAt: now, imageFileName: imageFileName,
                  wordFrame: imageFileName == nil ? nil : $0.frame)
        }

        // 이미 있는 낱말은 다시 모은 것이므로 새 사진과 함께 맨 앞으로 옮긴다
        entries = Array((newEntries + entries.filter { !seen.contains($0.text) }).prefix(Self.maximumCount))
        save()
        return unique.count
    }

    func remove(atOffsets offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func remove(ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
        } catch {
            // 저장 실패는 다음 저장 때 다시 시도되므로, 연습 흐름을 끊지 않도록 화면에 알리지 않는다
            print("단어장 저장 실패: \(error)")
        }
        removeUnusedImages()
    }

    private func saveImage(_ data: Data) -> String? {
        let name = UUID().uuidString + ".jpg"
        do {
            try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            try data.write(to: imagesDirectory.appending(path: name), options: .atomic)
            return name
        } catch {
            print("단어장 사진 저장 실패: \(error)")
            return nil
        }
    }

    /// 낱말을 지우거나 새 사진으로 바꾸면 아무 낱말도 쓰지 않는 사진이 남으므로 정리한다
    private func removeUnusedImages() {
        let used = Set(entries.compactMap(\.imageFileName))
        let files = (try? FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)) ?? []
        for file in files where !used.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func load(from url: URL) -> [Entry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }
}
