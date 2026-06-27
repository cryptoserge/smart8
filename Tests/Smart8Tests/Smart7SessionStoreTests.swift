import XCTest
@testable import Smart8

@MainActor
final class Smart7SessionStoreTests: XCTestCase {
    private let recipeKey = "Smart8.savedRecipes.v1"
    private let defaultRecipeKey = "Smart8.defaultRecipeID.v1"
    private let drainDelayKey = "Smart8.drainStartDelaySeconds.v1"
    private let builtInRecipeMigrationKey = "Smart8.builtInRecipesMigrated.v1"

    override func setUp() {
        super.setUp()
        clearRecipeDefaults()
    }

    override func tearDown() {
        clearRecipeDefaults()
        super.tearDown()
    }

    func testDefaultRecipeIsSelectedOnLaunch() throws {
        let first = Smart7Recipe.kaoriSaku18g
        let second = Smart7Recipe(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "夜のレシピ",
            temperatureCelsius: 90,
            coffeeGrams: 16,
            steps: [Smart7RecipeStep(volumeML: 180, pourSeconds: 30, intervalSeconds: 0)]
        )
        let encoded = try JSONEncoder().encode([first, second])
        UserDefaults.standard.set(encoded, forKey: recipeKey)
        UserDefaults.standard.set(second.id.uuidString, forKey: defaultRecipeKey)

        let store = Smart7SessionStore()

        XCTAssertEqual(store.recipe.id, second.id)
        XCTAssertEqual(store.selectedRecipeID, second.id)
        XCTAssertEqual(store.defaultRecipeID, second.id)
        XCTAssertTrue(store.isCurrentRecipeDefault)
    }

    func testSetCurrentRecipeAsDefaultPersistsSelection() throws {
        let first = Smart7Recipe.kaoriSaku18g
        let second = Smart7Recipe(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "朝のレシピ",
            temperatureCelsius: 92,
            coffeeGrams: 20,
            steps: [Smart7RecipeStep(volumeML: 240, pourSeconds: 40, intervalSeconds: 0)]
        )
        let encoded = try JSONEncoder().encode([first, second])
        UserDefaults.standard.set(encoded, forKey: recipeKey)

        let store = Smart7SessionStore()
        store.selectRecipe(second.id)
        store.setCurrentRecipeAsDefault()

        let relaunchedStore = Smart7SessionStore()
        XCTAssertEqual(relaunchedStore.recipe.id, second.id)
        XCTAssertEqual(relaunchedStore.defaultRecipeID, second.id)
        XCTAssertTrue(relaunchedStore.isCurrentRecipeDefault)
    }

    func testBuiltInRecipesAreAvailableWhenSavedRecipesExist() throws {
        let custom = Smart7Recipe(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "保存済みレシピ",
            temperatureCelsius: 91,
            coffeeGrams: 17,
            steps: [Smart7RecipeStep(volumeML: 250, pourSeconds: 40, intervalSeconds: 0)]
        )
        let encoded = try JSONEncoder().encode([custom])
        UserDefaults.standard.set(encoded, forKey: recipeKey)

        let store = Smart7SessionStore()

        XCTAssertTrue(store.savedRecipes.contains { $0.id == custom.id })
        for builtInRecipe in Smart7Recipe.builtInRecipes {
            XCTAssertTrue(store.savedRecipes.contains { $0.id == builtInRecipe.id })
        }
    }

    func testBuiltInRecipeMigrationDoesNotReAddDeletedRecipe() throws {
        let encoded = try JSONEncoder().encode(Smart7Recipe.builtInRecipes)
        UserDefaults.standard.set(encoded, forKey: recipeKey)
        UserDefaults.standard.set(true, forKey: builtInRecipeMigrationKey)

        let store = Smart7SessionStore()
        store.selectRecipe(Smart7Recipe.standard15g.id)
        store.deleteCurrentRecipe()

        let relaunchedStore = Smart7SessionStore()

        XCTAssertFalse(relaunchedStore.savedRecipes.contains { $0.id == Smart7Recipe.standard15g.id })
    }

    func testDrainStartDelayPersistsSelection() {
        let store = Smart7SessionStore()
        store.setDrainStartDelaySeconds(12)

        let relaunchedStore = Smart7SessionStore()

        XCTAssertEqual(relaunchedStore.drainStartDelaySeconds, 12)
    }

    func testDrainStartDelayClampsToSupportedRange() {
        let store = Smart7SessionStore()

        store.setDrainStartDelaySeconds(-4)
        XCTAssertEqual(store.drainStartDelaySeconds, 0)

        store.setDrainStartDelaySeconds(45)
        XCTAssertEqual(store.drainStartDelaySeconds, 30)
    }

    private func clearRecipeDefaults() {
        UserDefaults.standard.removeObject(forKey: recipeKey)
        UserDefaults.standard.removeObject(forKey: defaultRecipeKey)
        UserDefaults.standard.removeObject(forKey: drainDelayKey)
        UserDefaults.standard.removeObject(forKey: builtInRecipeMigrationKey)
    }
}
