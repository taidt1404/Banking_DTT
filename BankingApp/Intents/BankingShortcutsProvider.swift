import AppIntents

public struct BankingShortcutsProvider: AppShortcutsProvider {
    public static let shortcutTitle: LocalizedStringResource = "Lưu Bill Ngân Hàng"
    public static let shortcutSystemImage = "doc.text.viewfinder"

    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveBillIntent(),
            phrases: [
                "Lưu bill với \(.applicationName)",
                "Quét bill \(.applicationName)"
            ],
            shortTitle: "Lưu Bill Ngân Hàng",
            systemImageName: "doc.text.viewfinder"
        )
    }
}
