import CoreGraphics
import Foundation
import Testing
@testable import ViewReader

@MainActor
@Suite("단어장")
struct WordBookTests {
    private let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "wordbook-test-\(UUID().uuidString)")
        .appending(path: "wordbook.json")

    @Test("낱말을 넣으면 문장부호를 떼고 새 낱말이 앞에 온다")
    func 낱말을_넣으면_앞에_온다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        wordBook.add(["토끼"])

        // when
        let actual = wordBook.add(["엄마!", "호랑이,"])

        // then
        #expect(actual == 2)
        #expect(wordBook.entries.map(\.text) == ["엄마", "호랑이", "토끼"])
    }

    @Test("이미 있는 낱말은 하나만 남기고 맨 앞으로 옮긴다")
    func 중복_낱말은_맨_앞으로_옮긴다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        wordBook.add(["토끼", "호랑이"])

        // when
        let actual = wordBook.add(["호랑이", "호랑이!"])

        // then
        #expect(actual == 1)
        #expect(wordBook.entries.map(\.text) == ["호랑이", "토끼"])
    }

    @Test("문장부호만 있는 낱말은 넣지 않는다")
    func 빈_낱말은_넣지_않는다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)

        // when
        let actual = wordBook.add(["…", "!"])

        // then
        #expect(actual == 0)
        #expect(wordBook.entries.isEmpty)
    }

    @Test("최대 개수를 넘으면 오래된 낱말부터 지운다")
    func 최대_개수를_넘으면_오래된_것부터_지운다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        wordBook.add((1...WordBook.maximumCount).map { "낱말\($0)" })

        // when
        wordBook.add(["새낱말"])

        // then
        #expect(wordBook.entries.count == WordBook.maximumCount)
        #expect(wordBook.entries.first?.text == "새낱말")
        #expect(!wordBook.entries.contains { $0.text == "낱말\(WordBook.maximumCount)" })
    }

    @Test("저장한 낱말은 다시 열어도 남아 있다")
    func 다시_열어도_남아_있다() {
        // given
        WordBook(fileURL: fileURL).add(["토끼", "호랑이"])

        // when
        let actual = WordBook(fileURL: fileURL).entries.map(\.text)

        // then
        #expect(actual == ["토끼", "호랑이"])
    }

    @Test("지운 낱말은 다시 열어도 없다")
    func 지운_낱말은_다시_열어도_없다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        wordBook.add(["토끼", "호랑이"])

        // when
        wordBook.remove(atOffsets: IndexSet(integer: 0))
        let actual = WordBook(fileURL: fileURL).entries.map(\.text)

        // then
        #expect(actual == ["호랑이"])
    }

    @Test("저장 파일이 깨져 있으면 빈 단어장으로 시작한다")
    func 깨진_파일이면_빈_단어장() throws {
        // given
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("깨진 내용".utf8).write(to: fileURL)

        // when
        let actual = WordBook(fileURL: fileURL).entries

        // then
        #expect(actual.isEmpty)
    }

    private var imagesDirectory: URL {
        fileURL.deletingLastPathComponent().appending(path: "wordbook-images")
    }

    private func imageFiles() -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path)) ?? []).sorted()
    }

    @Test("사진과 함께 넣으면 고른 낱말들이 사진 한 장과 각자의 위치를 갖는다")
    func 사진과_위치를_함께_저장한다() throws {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        let frame = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.05)

        // when
        wordBook.add([.init(text: "토끼", frame: frame), .init(text: "호랑이")], imageData: Data("사진".utf8))

        // then
        let actual = wordBook.entries
        let imageName = try #require(actual.first?.imageFileName)
        #expect(actual.map(\.imageFileName) == [imageName, imageName])
        #expect(actual.first?.wordFrame == frame)
        #expect(actual.last?.wordFrame == nil)
        #expect(imageFiles() == [imageName])
        #expect(try Data(contentsOf: #require(wordBook.imageURL(for: actual[0]))) == Data("사진".utf8))
    }

    @Test("사진 없이 넣으면 위치도 저장하지 않는다")
    func 사진이_없으면_위치도_없다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)

        // when
        wordBook.add([.init(text: "토끼", frame: CGRect(x: 0, y: 0, width: 1, height: 1))])

        // then
        #expect(wordBook.entries.first?.imageFileName == nil)
        #expect(wordBook.entries.first?.wordFrame == nil)
        #expect(wordBook.imageURL(for: wordBook.entries[0]) == nil)
    }

    @Test("넣을 낱말이 없으면 사진도 저장하지 않는다")
    func 낱말이_없으면_사진도_없다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)

        // when
        let actual = wordBook.add([.init(text: "…")], imageData: Data("사진".utf8))

        // then
        #expect(actual == 0)
        #expect(imageFiles().isEmpty)
    }

    @Test("사진을 쓰는 낱말이 모두 지워지면 사진도 지운다")
    func 쓰지_않는_사진은_지운다() {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        wordBook.add([.init(text: "토끼"), .init(text: "호랑이")], imageData: Data("사진".utf8))
        let ids = Set(wordBook.entries.map(\.id))

        // when
        wordBook.remove(ids: [ids.first!])
        let actualAfterOne = imageFiles().count
        wordBook.remove(ids: ids)

        // then
        #expect(actualAfterOne == 1)
        #expect(imageFiles().isEmpty)
        #expect(wordBook.entries.isEmpty)
    }

    @Test("같은 낱말을 새 사진으로 다시 모으면 예전 사진은 지운다")
    func 다시_모으면_예전_사진을_지운다() throws {
        // given
        let wordBook = WordBook(fileURL: fileURL)
        wordBook.add([.init(text: "토끼")], imageData: Data("예전".utf8))
        let oldImage = try #require(wordBook.entries.first?.imageFileName)

        // when
        wordBook.add([.init(text: "토끼!")], imageData: Data("새것".utf8))

        // then
        let actual = try #require(wordBook.entries.first?.imageFileName)
        #expect(wordBook.entries.count == 1)
        #expect(actual != oldImage)
        #expect(imageFiles() == [actual])
    }

    @Test("사진 기능 전에 저장한 단어장도 읽는다")
    func 예전_형식도_읽는다() throws {
        // given
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let oldFormat = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","text":"토끼","savedAt":0}]"#
        try Data(oldFormat.utf8).write(to: fileURL)

        // when
        let actual = WordBook(fileURL: fileURL).entries

        // then
        #expect(actual.map(\.text) == ["토끼"])
        #expect(actual.first?.imageFileName == nil)
    }
}
