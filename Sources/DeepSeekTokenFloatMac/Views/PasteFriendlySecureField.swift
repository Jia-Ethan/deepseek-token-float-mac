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
        textField.textColor = NSColor(calibratedRed: 0.1137, green: 0.1137, blue: 0.1216, alpha: 1)
        textField.backgroundColor = NSColor(calibratedWhite: 1, alpha: 0.96)
        textField.placeholderAttributedString = attributedPlaceholder(placeholder)
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.commit(_:))
        return textField
    }

    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        context.coordinator.text = $text
        nsView.placeholderAttributedString = attributedPlaceholder(placeholder)
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    private func attributedPlaceholder(_ placeholder: String) -> NSAttributedString {
        NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor(calibratedRed: 0.1137, green: 0.1137, blue: 0.1216, alpha: 0.48),
                .font: NSFont.systemFont(ofSize: 13)
            ]
        )
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
