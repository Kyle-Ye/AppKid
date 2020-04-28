//
//  Event+XInput2.swift
//  AppKid
//
//  Created by Serhii Mumriak on 21.04.2020.
//

import Foundation
import CoreFoundation
import CX11.X
import CX11.Xlib
import CXInput2

fileprivate extension XEvent {
    var eventTypeFromXInput2Event: Event.EventType {
        switch xcookie.xInput2EventType {
        case .keyPress, .keyRelease:
            return keyboardEventType

        case .buttonPress, .buttonRelease, .motion:
            return mouseEventType

        case .enter:
            return .mouseEntered

        case .leave:
            return .mouseExited

        default:
            return .noEvent
        }
    }
}

fileprivate extension XEvent {
    var keyboardEventType: Event.EventType {
        switch xcookie.xInput2EventType {
        case .keyPress: return .keyDown
        case .keyRelease: return .keyUp
        default: return .noEvent
        }
    }

    var mouseEventType: Event.EventType {
        switch xcookie.xInput2EventType {
        case .buttonPress: return deviceEvent.button.downEventType
        case .buttonRelease: return deviceEvent.button.upEventType
        case .motion: return deviceEvent.button.moveEventType
        default: return .noEvent
        }
    }
}

internal extension Event {
    convenience init(xInput2Event: XEvent, timestamp: TimeInterval, displayServer: DisplayServer) throws {
        let type = xInput2Event.eventTypeFromXInput2Event

        if type == .noEvent {
            let eventString = xInput2Event.xcookie.xInput2EventType.map { String(reflecting: $0) } ?? "unknown"
            throw EventCreationError.nativeEventIgnored(description: "XInput2 event type: \(eventString)")
        }

        let deviceEvent: XIDeviceEvent = xInput2Event.deviceEvent

        let application = Application.shared

        guard let windowNumber = application.windows.firstIndex(where: { $0.nativeWindow.windowID == deviceEvent.event }) else {
            let eventString = xInput2Event.xcookie.xInput2EventType.map { String(reflecting: $0) } ?? "unknown"
            throw EventCreationError.noWindow(description: "XInput2 event type: \(eventString). Foreign window ID: \(deviceEvent.event)")
        }

        let window = application.windows[windowNumber]
        let nativeWindow = window.nativeWindow

        if type == .mouseMoved && window.acceptsMouseMovedEvents == false {
            throw EventCreationError.eventIgnored(description: "Window does not accept mouse move event.")
        }

        switch type {
        case _ where type.isAnyMouse:
            let deviceEvent = xInput2Event.deviceEvent
            let location = CGPoint(x: CGFloat(deviceEvent.event_x) / displayServer.displayScale, y: CGFloat(deviceEvent.event_y) / displayServer.displayScale)
            try self.init(withMouseEventType: type, location: location, modifierFlags: displayServer.x11Context.currentModifierFlags, timestamp: timestamp, windowNumber: windowNumber, eventNumber: 0, clickCount: 0, pressure: 0.0)

            buttonNumber = Int(deviceEvent.detail)

        case _ where type.isAnyKeyboard:
            let keyCode = UInt32(deviceEvent.detail)
            var keySymbol: KeySym = KeySym(NoSymbol)
            var lookupString: String? = nil

            if let inputContext = nativeWindow.inputContext {
                var fakeEvent = deviceEvent.generatedKeyPressedEvent
                var buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 32)
                defer {
                    buffer.deallocate()
                }
                buffer.initialize(to: 0)

                var status: CInt = 0

                let bytesWritten = Xutf8LookupString(inputContext, &fakeEvent, buffer, 32, &keySymbol, &status)

                if status == XLookupChars || status == XLookupBoth {
                    buffer[Int(bytesWritten)] = 0
                    lookupString = String(cString: buffer, encoding: .utf8)
                }
            }

            if keySymbol == NoSymbol {
                throw EventCreationError.eventIgnored(description: "Keyboard event with invalid key symbol. Key code: \(keyCode)")
            } else {
                let location = CGPoint(x: CGFloat.nan, y: CGFloat.nan)

                //palkovnik:WORKAROUND:swift generates intializer that actually allows initialization with invalid value :/
                if let x11ModifierKeySymbol = X11ModifierKeySymbol(rawValue: keySymbol), x11ModifierKeySymbol.isValidRawValue {
                    let modifierFlag = x11ModifierKeySymbol.modifierFlag

                    if type == .keyDown {
                        displayServer.x11Context.currentModifierFlags.formUnion(modifierFlag)
                    } else {
                        displayServer.x11Context.currentModifierFlags.formSymmetricDifference(modifierFlag)
                    }

                    self.init(type: .flagsChanged, location: location, modifierFlags: displayServer.x11Context.currentModifierFlags, windowNumber: windowNumber)

                } else {
                    self.init(type: type, location: location, modifierFlags: displayServer.x11Context.currentModifierFlags, windowNumber: windowNumber)

                    characters = lookupString.flatMap { $0.isEmpty ? nil : $0 }
                    isARepeat = deviceEvent.flags & XIKeyRepeat != 0
                }

                self.keyCode = keyCode
            }

        default:
            throw EventCreationError.eventIgnored(description: "Event type: \(type)")
        }
    }
}
