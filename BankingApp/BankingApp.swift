import SwiftUI
import SwiftData

@main
public struct BankingApp: App {
    public static func createModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    public var sharedModelContainer: ModelContainer = BankingApp.createModelContainer()

    public init() {}

    public init(modelContainer: ModelContainer) {
        self.sharedModelContainer = modelContainer
    }

    public var body: some Scene {
        WindowGroup {
            TabView {
                DailyTimelineView()
                    .tabItem {
                        Label("Sổ ngày", systemImage: "calendar")
                    }

                NavigationStack {
                    ShortcutsSetupGuideView()
                }
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
