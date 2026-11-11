import AVFoundation
import SwiftUI

@main
struct ViewReaderApp: App {
    init() {
        // 기본 오디오 세션은 무음 스위치를 켜면 소리가 나지 않는다 — 읽어 주기 앱이므로 항상 들리게 한다
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
