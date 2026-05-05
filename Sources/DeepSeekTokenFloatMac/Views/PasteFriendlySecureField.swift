import AppKit
import SwiftUI

struct PasteFriendlySecureField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = NSSecureTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingMiddle
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.focusRingType = .default
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.commit(_:))
        return textField
    }

    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        context.coordinator.text = $text
        nsView.placeholderString = placeholder
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            text.wrappedValue = textField.stringValue
        }

        @objc func commit(_ sender: NSSecureTextField) {
            text.wrappedValue = sender.stringValue
        }
    }
}
