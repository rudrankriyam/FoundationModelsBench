import Foundation

public struct FoundationModelsBenchSample: Codable, Identifiable, Sendable {
    public let id: String
    public let prompt: String
    public let checks: [FoundationModelsBenchCheck]
    public let visualFixture: FoundationModelsBenchVisualFixture?
    public let safetyExpectation: FoundationModelsBenchSafetyExpectation?

    public init(
        id: String,
        prompt: String,
        checks: [FoundationModelsBenchCheck],
        visualFixture: FoundationModelsBenchVisualFixture? = nil,
        safetyExpectation: FoundationModelsBenchSafetyExpectation? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.checks = checks
        self.visualFixture = visualFixture
        self.safetyExpectation = safetyExpectation
    }
}

public struct FoundationModelsBenchScenario: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: FoundationModelsBenchScenarioCategory
    public let inspiredBy: [String]
    public let instructions: String
    public let outputMode: FoundationModelsBenchOutputMode
    public let maximumResponseTokens: Int
    public let toolSet: FoundationModelsBenchToolSet
    public let requiresOS27: Bool
    public let samples: [FoundationModelsBenchSample]

    public var prompt: String { samples.first?.prompt ?? "" }
    public var checks: [FoundationModelsBenchCheck] { samples.first?.checks ?? [] }

    public init(
        id: String,
        title: String,
        summary: String,
        category: FoundationModelsBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        prompt: String,
        outputMode: FoundationModelsBenchOutputMode,
        maximumResponseTokens: Int,
        checks: [FoundationModelsBenchCheck],
        toolSet: FoundationModelsBenchToolSet = .none,
        requiresOS27: Bool = false
    ) {
        self.init(
            id: id,
            title: title,
            summary: summary,
            category: category,
            inspiredBy: inspiredBy,
            instructions: instructions,
            outputMode: outputMode,
            maximumResponseTokens: maximumResponseTokens,
            toolSet: toolSet,
            requiresOS27: requiresOS27,
            samples: [.init(id: "\(id)-001", prompt: prompt, checks: checks)]
        )
    }

    public init(
        id: String,
        title: String,
        summary: String,
        category: FoundationModelsBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        outputMode: FoundationModelsBenchOutputMode,
        maximumResponseTokens: Int,
        toolSet: FoundationModelsBenchToolSet = .none,
        requiresOS27: Bool = false,
        samples: [FoundationModelsBenchSample]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.inspiredBy = inspiredBy
        self.instructions = instructions
        self.outputMode = outputMode
        self.maximumResponseTokens = maximumResponseTokens
        self.toolSet = toolSet
        self.requiresOS27 = requiresOS27
        self.samples = samples
    }
}
