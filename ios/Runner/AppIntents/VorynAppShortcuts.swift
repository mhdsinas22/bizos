import AppIntents

// MARK: - Voryn App Shortcuts Reference
// Maintains AppShortcutsProvider with localized Siri phrases:
// - "Hey Siri, add expense in Voryn"
// - "Hey Siri, log expense in Voryn"
// - "Hey Siri, add expense with Voryn"
// - "Quick add expense in Voryn"
// The provider definition is compiled as part of the Runner target in QuickExpenseIntent.swift.

@available(iOS 16.0, *)
typealias VorynShortcutsProvider = VorynAppShortcuts
