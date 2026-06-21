import Foundation
import Testing
@testable import PeekPairsCore

@Suite("App settings")
struct AppSettingsTests {
    @Test("legacy settings default focus-loss minimization when the key is absent")
    func legacySettingsDefaultMinimizeOnFocusLoss() throws {
        let data = """
        {
          "boardSize" : { "dimension" : 6 },
          "hotkeys" : [
            "openPausedBoard",
            {
              "carbonModifiers" : 6400,
              "displayText" : "⌃⌥⌘M",
              "keyCode" : 46
            },
            "resumeOrStartGame",
            {
              "carbonModifiers" : 6400,
              "displayText" : "⌃⌥⌘P",
              "keyCode" : 35
            },
            "startNewGame",
            {
              "carbonModifiers" : 6400,
              "displayText" : "⌃⌥⌘N",
              "keyCode" : 45
            }
          ]
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(settings.boardSize.dimension == 6)
        #expect(settings.defaultWindowWidth == AppSettings.defaultWindowWidth)
        #expect(settings.minimizeOnFocusLoss == true)
        #expect(settings.hotkeys[.resumeOrStartGame]?.displayText == "⌃⌥⌘P")
    }

    @Test("default app window width is clamped while decoding")
    func defaultWindowWidthClampsWhileDecoding() throws {
        let data = """
        {
          "boardSize" : { "dimension" : 6 },
          "defaultWindowWidth" : 2400,
          "hotkeys" : [],
          "minimizeOnFocusLoss" : true
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(settings.defaultWindowWidth == AppSettings.maximumDefaultWindowWidth)
    }
}
