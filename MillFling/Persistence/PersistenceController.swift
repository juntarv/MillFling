import CoreData

final class PersistenceController {
    static let shared = PersistenceController(inMemory: false)
    /// Separate throwaway store for `-screenshotTour`, so tour seeding never touches real progress.
    static let tour = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool) {
        container = NSPersistentContainer(name: "MillFling")
        if inMemory, let description = container.persistentStoreDescriptions.first {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        // Model v1 -> v2 only adds optional/defaulted attributes and entities: lightweight migration.
        container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
        var loadFailed = false
        container.loadPersistentStores { _, error in
            if error != nil { loadFailed = true }
        }
        if loadFailed && !inMemory {
            // Never leave the player on a dead screen: rebuild an unreadable store from scratch.
            if let url = container.persistentStoreDescriptions.first?.url {
                try? container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            }
            container.loadPersistentStores { _, _ in }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
