import XCTest
@testable import Smart8

final class Smart7RecipeTests: XCTestCase {
    func testKaoriSaku18gRecipeValues() {
        let recipe = Smart7Recipe.kaoriSaku18g
        XCTAssertEqual(recipe.name, "香り咲く18g")
        XCTAssertEqual(recipe.temperatureCelsius, 94)
        XCTAssertEqual(recipe.coffeeGrams, 18)
        XCTAssertEqual(recipe.totalWaterML, 290)
        XCTAssertEqual(recipe.steps, [
            Smart7RecipeStep(volumeML: 40, pourSeconds: 12, intervalSeconds: 45),
            Smart7RecipeStep(volumeML: 70, pourSeconds: 21, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 70, pourSeconds: 21, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 110, pourSeconds: 33, intervalSeconds: 0)
        ])
    }

    func testBuiltInRecipesIncludeGeneralPurposePresets() {
        XCTAssertEqual(Smart7Recipe.builtInRecipes.map(\.name), [
            "香り咲く18g",
            "標準15g",
            "しっかり20g",
            "浅煎りクリア18g",
            "深煎りまろやか18g"
        ])
        XCTAssertEqual(Smart7Recipe.standard15g.totalWaterML, 240)
        XCTAssertEqual(Smart7Recipe.rich20g.totalWaterML, 320)
        XCTAssertEqual(Smart7Recipe.lightRoastClear18g.totalWaterML, 300)
        XCTAssertEqual(Smart7Recipe.darkRoastMellow18g.totalWaterML, 270)
        XCTAssertTrue(Smart7Recipe.builtInRecipes.allSatisfy { (80...96).contains($0.temperatureCelsius) })
        XCTAssertTrue(Smart7Recipe.builtInRecipes.allSatisfy { !$0.steps.isEmpty })
    }

    func testRecipeSequenceOrderAndDelays() throws {
        let recipe = Smart7Recipe.kaoriSaku18g
        let sequence = try Smart7Protocol.recipeSequence(
            temperatureCelsius: recipe.temperatureCelsius,
            steps: recipe.steps
        )
        XCTAssertEqual(sequence.map(\.label), ["レシピ初期化", "工程1", "工程2", "工程3", "工程4", "温度設定", "抽出開始"])
        XCTAssertEqual(sequence.map(\.delayBeforeMilliseconds), [0, 200, 200, 200, 200, 100, 100])
        XCTAssertEqual(sequence.map(\.plain), [
            data("99 05 00 05"),
            data("99 01 04 01 04 0C 2D 43"),
            data("99 01 04 02 07 15 14 37"),
            data("99 01 04 03 07 15 14 38"),
            data("99 01 04 04 0B 21 00 35"),
            data("99 0A 01 5E 69"),
            data("99 02 01 01 04")
        ])
    }

    func testCustomRecipeCodableAndSequence() throws {
        let recipe = Smart7Recipe(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "朝のマイレシピ",
            temperatureCelsius: 92,
            coffeeGrams: 20,
            steps: [
                Smart7RecipeStep(volumeML: 50, pourSeconds: 10, intervalSeconds: 30),
                Smart7RecipeStep(volumeML: 80, pourSeconds: 20, intervalSeconds: 10)
            ]
        )

        let decoded = try JSONDecoder().decode(Smart7Recipe.self, from: JSONEncoder().encode(recipe))
        XCTAssertEqual(decoded, recipe)

        let sequence = try Smart7Protocol.recipeSequence(
            temperatureCelsius: decoded.temperatureCelsius,
            steps: decoded.steps
        )
        XCTAssertEqual(sequence.map(\.label), ["レシピ初期化", "工程1", "工程2", "温度設定", "抽出開始"])
        XCTAssertEqual(sequence.map(\.plain), [
            data("99 05 00 05"),
            data("99 01 04 01 05 0A 1E 33"),
            data("99 01 04 02 08 14 0A 2D"),
            data("99 0A 01 5C 67"),
            data("99 02 01 01 04")
        ])
    }

    private func data(_ hex: String) -> Data {
        Data(hex.split(separator: " ").map { UInt8($0, radix: 16)! })
    }
}
