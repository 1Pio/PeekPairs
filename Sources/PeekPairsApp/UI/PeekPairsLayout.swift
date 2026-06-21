import CoreGraphics
import PeekPairsCore

enum PeekPairsLayout {
    static let minimumWindowWidth = CGFloat(AppSettings.minimumDefaultWindowWidth)
    static let contentPadding: CGFloat = 24
    static let boardToControlsSpacing: CGFloat = 14
    static let bottomChromeHeight: CGFloat = 40
    static let bottomChromeTotalHeight = boardToControlsSpacing + bottomChromeHeight
    static let controlButtonSide: CGFloat = 38
    static let boardCornerRadius: CGFloat = 18
    static let windowCornerRadius = boardCornerRadius + contentPadding

    static func windowHeight(forWidth width: CGFloat) -> CGFloat {
        width + bottomChromeTotalHeight
    }

    static func windowSize(forDefaultWidth width: Double) -> CGSize {
        let clampedWidth = CGFloat(AppSettings.clampedDefaultWindowWidth(width))
        return CGSize(width: clampedWidth, height: windowHeight(forWidth: clampedWidth))
    }
}
