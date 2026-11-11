import SwiftUI

/// 책에서 모은 낱말 목록 — 카드 연습으로 가거나, 낱말을 골라 연습하거나 지운다
struct WordBookView: View {
    let wordBook: WordBook
    let speech: SpeechReader

    @State private var path = NavigationPath()
    @State private var selectedIDs = Set<UUID>()
    @State private var editMode: EditMode = .inactive
    @State private var isDeleteConfirmationPresented = false
    @Environment(\.dismiss) private var dismiss

    enum Route: Hashable {
        case practice(WordBook.Entry)
        case flashcards
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if wordBook.entries.isEmpty {
                    ContentUnavailableView(
                        "아직 모은 낱말이 없어요",
                        systemImage: "book.closed",
                        description: Text("책을 비추고 카메라 버튼을 눌러\n낱말을 모아 보세요.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("단어장")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .practice(let entry):
                    PracticeView(entry: entry, wordBook: wordBook, speech: speech)
                case .flashcards:
                    FlashcardView(wordBook: wordBook, speech: speech)
                }
            }
            .toolbar { toolbar }
            .environment(\.editMode, $editMode)
            .confirmationDialog(
                "고른 낱말 \(selectedIDs.count)개를 지울까요?",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("지우기", role: .destructive) {
                    wordBook.remove(ids: selectedIDs)
                    selectedIDs = []
                    editMode = .inactive
                }
            }
        }
    }

    private var list: some View {
        List(selection: $selectedIDs) {
            if !editMode.isEditing {
                Section {
                    Button {
                        path.append(Route.flashcards)
                    } label: {
                        Label("카드로 연습하기 (\(wordBook.entries.count)개)", systemImage: "rectangle.on.rectangle.angled")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }

            Section {
                ForEach(wordBook.entries) { entry in
                    row(entry)
                        .tag(entry.id)
                        .contextMenu {
                            Button("지우기", systemImage: "trash", role: .destructive) {
                                wordBook.remove(ids: [entry.id])
                            }
                        }
                }
                .onDelete { wordBook.remove(atOffsets: $0) }
            } footer: {
                if !editMode.isEditing {
                    Text("왼쪽으로 밀거나 길게 눌러도 지울 수 있어요.")
                }
            }
        }
    }

    private func row(_ entry: WordBook.Entry) -> some View {
        Button {
            guard !editMode.isEditing else { return }
            path.append(Route.practice(entry))
        } label: {
            HStack {
                Text(entry.text)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if entry.imageFileName != nil {
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
                if !editMode.isEditing {
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !wordBook.entries.isEmpty {
                Button(editMode.isEditing ? "취소" : "편집") {
                    selectedIDs = []
                    editMode = editMode.isEditing ? .inactive : .active
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            if editMode.isEditing {
                Button("지우기", role: .destructive) {
                    isDeleteConfirmationPresented = true
                }
                .disabled(selectedIDs.isEmpty)
            } else {
                Button("완료") { dismiss() }
            }
        }
    }
}
