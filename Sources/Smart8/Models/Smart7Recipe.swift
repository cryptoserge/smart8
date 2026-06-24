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
}
