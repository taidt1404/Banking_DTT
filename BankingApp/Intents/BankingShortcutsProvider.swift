import AppIntents

public struct BankingShortcutsProvider: AppShortcutsProvider {
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
