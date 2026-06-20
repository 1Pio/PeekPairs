import Carbon
import Foundation
import PeekPairsCore

enum HotkeyRegistrationStatus: Equatable {
    case registered
    case unavailable(OSStatus)

    var displayText: String {
        switch self {
        case .registered:
            "Active"
        case .unavailable(let status):
            "Unavailable (\(status))"
        }
    }
}

final class GlobalHotkeyCenter: @unchecked Sendable {
    typealias Handler = @Sendable (HotkeyAction) -> Void

    private let handler: Handler
    private var eventHandlerRef: EventHandlerRef?
    private var refs: [HotkeyAction: EventHotKeyRef?] = [:]

    init(handler: @escaping Handler) {
        self.handler = handler
        installHandler()
    }

    deinit {
        unregisterAll()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func register(bindings: [HotkeyAction: HotkeyBinding]) -> [HotkeyAction: HotkeyRegistrationStatus] {
        unregisterAll()

        var statuses: [HotkeyAction: HotkeyRegistrationStatus] = [:]

        for action in HotkeyAction.allCases {
            guard let binding = bindings[action] else { continue }
            var hotkeyRef: EventHotKeyRef?
            let hotkeyID = EventHotKeyID(signature: Self.signature, id: action.carbonID)
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.carbonModifiers,
                hotkeyID,
                GetApplicationEventTarget(),
                OptionBits(kEventHotKeyNoOptions),
                &hotkeyRef
            )

            if status == noErr {
                refs[action] = hotkeyRef
                statuses[action] = .registered
            } else {
                statuses[action] = .unavailable(status)
            }
        }

        return statuses
    }

    private func installHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                let center = Unmanaged<GlobalHotkeyCenter>.fromOpaque(userData).takeUnretainedValue()
                var hotkeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )

                guard status == noErr, let action = HotkeyAction(carbonID: hotkeyID.id) else {
                    return status
                }

                let handler = center.handler
                DispatchQueue.main.async {
                    handler(action)
                }

                return noErr
            },
            1,
            &eventSpec,
            selfPointer,
            &eventHandlerRef
        )
    }

    private func unregisterAll() {
        for ref in refs.values {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        refs.removeAll()
    }

    private static let signature: OSType = {
        let scalars = Array("PkPr".unicodeScalars).map(\.value)
        return scalars.reduce(0) { ($0 << 8) + OSType($1) }
    }()
}

private extension HotkeyAction {
    var carbonID: UInt32 {
        switch self {
        case .openPausedBoard:
            1
        case .startNewGame:
            2
        case .resumeOrStartGame:
            3
        }
    }

    init?(carbonID: UInt32) {
        switch carbonID {
        case 1:
            self = .openPausedBoard
        case 2:
            self = .startNewGame
        case 3:
            self = .resumeOrStartGame
        default:
            return nil
        }
    }
}
