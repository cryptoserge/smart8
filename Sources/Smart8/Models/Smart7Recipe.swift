import Foundation

public struct Smart7Recipe: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var temperatureCelsius: Int
    public var coffeeGrams: Int
    public var steps: [Smart7RecipeStep]

    public init(
        id: UUID = UUID(),
        name: String,
        temperatureCelsius: Int,
        coffeeGrams: Int,
        steps: [Smart7RecipeStep]
    ) {
        self.id = id
        self.name = name
        self.temperatureCelsius = temperatureCelsius
        self.coffeeGrams = coffeeGrams
        self.steps = steps
    }

    public var totalWaterML: Int {
        steps.reduce(0) { $0 + $1.volumeML }
    }

    public static let kaoriSaku18g = Smart7Recipe(
        id: UUID(uuidString: "8DD9C6D4-75BD-4910-B142-B3A3AB82FB90")!,
        name: "香り咲く18g",
        temperatureCelsius: 94,
        coffeeGrams: 18,
        steps: [
            Smart7RecipeStep(volumeML: 40, pourSeconds: 12, intervalSeconds: 45),
            Smart7RecipeStep(volumeML: 70, pourSeconds: 21, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 70, pourSeconds: 21, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 110, pourSeconds: 33, intervalSeconds: 0)
        ]
    )

    public static let standard15g = Smart7Recipe(
        id: UUID(uuidString: "EF0600DA-C6FC-4B6F-9DEB-462EB5F7F9C6")!,
        name: "標準15g",
        temperatureCelsius: 92,
        coffeeGrams: 15,
        steps: [
            Smart7RecipeStep(volumeML: 40, pourSeconds: 10, intervalSeconds: 35),
            Smart7RecipeStep(volumeML: 70, pourSeconds: 18, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 70, pourSeconds: 18, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 60, pourSeconds: 15, intervalSeconds: 0)
        ]
    )

    public static let rich20g = Smart7Recipe(
        id: UUID(uuidString: "A16C8F45-F37E-4B69-A317-C9DBA029354A")!,
        name: "しっかり20g",
        temperatureCelsius: 94,
        coffeeGrams: 20,
        steps: [
            Smart7RecipeStep(volumeML: 60, pourSeconds: 15, intervalSeconds: 35),
            Smart7RecipeStep(volumeML: 90, pourSeconds: 22, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 90, pourSeconds: 22, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 80, pourSeconds: 20, intervalSeconds: 0)
        ]
    )

    public static let lightRoastClear18g = Smart7Recipe(
        id: UUID(uuidString: "54D0F86D-B23E-47EF-8631-71F76EA3B7E5")!,
        name: "浅煎りクリア18g",
        temperatureCelsius: 96,
        coffeeGrams: 18,
        steps: [
            Smart7RecipeStep(volumeML: 50, pourSeconds: 12, intervalSeconds: 40),
            Smart7RecipeStep(volumeML: 80, pourSeconds: 20, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 80, pourSeconds: 20, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 90, pourSeconds: 24, intervalSeconds: 0)
        ]
    )

    public static let darkRoastMellow18g = Smart7Recipe(
        id: UUID(uuidString: "40B8EB24-7994-4A9F-89E6-BDDCC54620A7")!,
        name: "深煎りまろやか18g",
        temperatureCelsius: 88,
        coffeeGrams: 18,
        steps: [
            Smart7RecipeStep(volumeML: 45, pourSeconds: 12, intervalSeconds: 35),
            Smart7RecipeStep(volumeML: 75, pourSeconds: 20, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 75, pourSeconds: 20, intervalSeconds: 20),
            Smart7RecipeStep(volumeML: 75, pourSeconds: 20, intervalSeconds: 0)
        ]
    )

    public static let builtInRecipes = [
        kaoriSaku18g,
        standard15g,
        rich20g,
        lightRoastClear18g,
        darkRoastMellow18g
    ]
}
