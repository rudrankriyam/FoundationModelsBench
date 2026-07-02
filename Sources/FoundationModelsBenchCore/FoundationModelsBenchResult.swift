import Foundation

public struct FoundationModelsBenchTrialResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let scenarioTitle: String
    public let category: FoundationModelsBenchScenarioCategory
    public let sample: FoundationModelsBenchSample
    public let requestedModel: FoundationModelsBenchModel
    public let executedModel: FoundationModelsBenchModel
    public let iteration: Int
    public let usedFallback: Bool
    public let fallbackReason: String?
    public let offlineSuccess: Bool
    public let toolCalls: [FoundationModelsBenchToolCall]
    public let finalState: FoundationModelsBenchStateSnapshot?
    public let safetyOutcome: FoundationModelsBenchSafetyOutcome
    public let safetyDetail: String?
    public let response: String
    public let grade: FoundationModelsBenchGrade
    public let metrics: FoundationModelsBenchTrialMetrics
    public let environment: EnvironmentSnapshot

    public init(
        id: UUID = UUID(),
        scenario: FoundationModelsBenchScenario,
        sample: FoundationModelsBenchSample,
        requestedModel: FoundationModelsBenchModel,
        executedModel: FoundationModelsBenchModel,
        iteration: Int,
        usedFallback: Bool = false,
        fallbackReason: String? = nil,
        offlineSuccess: Bool = false,
        toolCalls: [FoundationModelsBenchToolCall] = [],
        finalState: FoundationModelsBenchStateSnapshot? = nil,
        safetyOutcome: FoundationModelsBenchSafetyOutcome = .notApplicable,
        safetyDetail: String? = nil,
        response: String,
        grade: FoundationModelsBenchGrade,
        metrics: FoundationModelsBenchTrialMetrics,
        environment: EnvironmentSnapshot
    ) {
        self.id = id
        self.scenarioID = scenario.id
        self.scenarioTitle = scenario.title
        self.category = scenario.category
        self.sample = sample
        self.requestedModel = requestedModel
        self.executedModel = executedModel
        self.iteration = iteration
        self.usedFallback = usedFallback
        self.fallbackReason = fallbackReason
        self.offlineSuccess = offlineSuccess
        self.toolCalls = toolCalls
        self.finalState = finalState
        self.safetyOutcome = safetyOutcome
        self.safetyDetail = safetyDetail
        self.response = response
        self.grade = grade
        self.metrics = metrics
        self.environment = environment
    }

    public var safetyPassed: Bool? {
        FoundationModelsBenchSafetyClassifier.passed(
            expectation: sample.safetyExpectation,
            outcome: safetyOutcome
        )
    }

    public var isCriticalSafetyFailure: Bool {
        safetyPassed == false
    }

    /// Whether this trial counts as a task success for pass-rate metrics.
    ///
    /// Trials with deterministic checks pass when every check passes. Safety
    /// trials that ship no checks (e.g. `mustProtect` guardrail probes) derive
    /// their result from the safety classifier instead, so a correct refusal
    /// counts as a task success and a harmful compliance counts as a failure.
    public var taskPassed: Bool {
        if grade.checks.isEmpty, sample.safetyExpectation != nil {
            return safetyPassed == true
        }
        return grade.promptPassed
    }
}

public struct FoundationModelsBenchFailure: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let sampleID: String
    public let iteration: Int
    public let kind: String
    public let message: String
    public let toolCalls: [FoundationModelsBenchToolCall]?
    public let finalState: FoundationModelsBenchStateSnapshot?

    public init(
        id: UUID = UUID(),
        scenarioID: String,
        sampleID: String,
        iteration: Int,
        kind: String,
        message: String,
        toolCalls: [FoundationModelsBenchToolCall]? = nil,
        finalState: FoundationModelsBenchStateSnapshot? = nil
    ) {
        self.id = id
        self.scenarioID = scenarioID
        self.sampleID = sampleID
        self.iteration = iteration
        self.kind = kind
        self.message = message
        self.toolCalls = toolCalls
        self.finalState = finalState
    }
}

public struct FoundationModelsBenchQuotaSnapshot: Codable, Sendable {
    public let status: String
    public let isApproachingLimit: Bool?
    public let isLimitReached: Bool
    public let resetDate: Date?

    public init(
        status: String,
        isApproachingLimit: Bool?,
        isLimitReached: Bool,
        resetDate: Date?
    ) {
        self.status = status
        self.isApproachingLimit = isApproachingLimit
        self.isLimitReached = isLimitReached
        self.resetDate = resetDate
    }
}

public struct FoundationModelsBenchScenarioSummary: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: FoundationModelsBenchScenarioCategory
    public let trialCount: Int
    public let failureCount: Int
    public let failureRate: Double
    public let promptPassRate: Double
    public let meanConstraintScore: Double
    public let safetyTrialCount: Int
    public let safetyPassRate: Double?
    public let guardrailViolationCount: Int
    public let refusalCount: Int
    public let criticalSafetyFailureCount: Int
    public let duration: FoundationModelsBenchDistribution
    public let timeToFirstToken: FoundationModelsBenchDistribution
    public let outputTokensPerSecond: FoundationModelsBenchDistribution
    public let peakObservedResidentMemoryBytes: FoundationModelsBenchDistribution

    public var endToEndPassRate: Double {
        let attemptCount = trialCount + failureCount
        guard attemptCount > 0 else { return 0 }
        let passingTrialCount = promptPassRate * Double(trialCount)
        return passingTrialCount / Double(attemptCount)
    }

    init(scenario: FoundationModelsBenchScenario, trials: [FoundationModelsBenchTrialResult], failureCount: Int) {
        id = scenario.id
        title = scenario.title
        category = scenario.category
        trialCount = trials.count
        self.failureCount = failureCount
        let attemptCount = trials.count + failureCount
        failureRate = attemptCount == 0 ? 0 : Double(failureCount) / Double(attemptCount)
        promptPassRate =
            trials.isEmpty
            ? 0
            : Double(trials.count(where: \.taskPassed)) / Double(trials.count)
        let gradedTrials = trials.filter { !$0.grade.checks.isEmpty }
        meanConstraintScore =
            gradedTrials.isEmpty
            ? 0
            : gradedTrials.map(\.grade.score).reduce(0, +) / Double(gradedTrials.count)
        let safetyTrials = trials.filter { $0.sample.safetyExpectation != nil }
        safetyTrialCount = safetyTrials.count
        safetyPassRate =
            safetyTrials.isEmpty
            ? nil
            : Double(safetyTrials.count(where: { $0.safetyPassed == true }))
                / Double(safetyTrials.count)
        guardrailViolationCount = safetyTrials.count(where: {
            $0.safetyOutcome == .guardrailViolation
        })
        refusalCount = safetyTrials.count(where: { $0.safetyOutcome == .refusal })
        criticalSafetyFailureCount = safetyTrials.count(where: \.isCriticalSafetyFailure)
        duration = FoundationModelsBenchDistribution(values: trials.map(\.metrics.duration))
        timeToFirstToken = FoundationModelsBenchDistribution(
            values: trials.compactMap(\.metrics.timeToFirstToken))
        outputTokensPerSecond = FoundationModelsBenchDistribution(
            values: trials.compactMap(\.metrics.outputTokensPerSecond))
        peakObservedResidentMemoryBytes = FoundationModelsBenchDistribution(
            values: trials.compactMap(\.metrics.peakObservedResidentMemoryBytes).map { Double($0) }
        )
    }
}

public struct FoundationModelsBenchRunResult: Codable, Sendable {
    public let suite: FoundationModelsBenchSuite
    public let model: FoundationModelsBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let sampleLimit: Int?
    public let sessionMode: FoundationModelsBenchSessionMode
    public let reasoningLevel: FoundationModelsBenchReasoningLevel
    public let fallbackMode: FoundationModelsBenchFallbackMode
    public let connectivity: FoundationModelsBenchConnectivity
    public let randomizedOrder: Bool
    public let randomSeed: UInt64
    public let modelContextSize: Int?
    public let quotaBefore: FoundationModelsBenchQuotaSnapshot?
    public let quotaAfter: FoundationModelsBenchQuotaSnapshot?
    public let startedAt: Date
    public let endedAt: Date
    public let environment: EnvironmentSnapshot
    public let trials: [FoundationModelsBenchTrialResult]
    public let failures: [FoundationModelsBenchFailure]
    public let summaries: [FoundationModelsBenchScenarioSummary]

    public var criticalSafetyFailureCount: Int {
        trials.count(where: \.isCriticalSafetyFailure)
    }

    public init(
        suite: FoundationModelsBenchSuite,
        model: FoundationModelsBenchModel,
        warmupCount: Int,
        repetitions: Int,
        sampleLimit: Int?,
        sessionMode: FoundationModelsBenchSessionMode,
        reasoningLevel: FoundationModelsBenchReasoningLevel,
        fallbackMode: FoundationModelsBenchFallbackMode,
        connectivity: FoundationModelsBenchConnectivity,
        randomizedOrder: Bool,
        randomSeed: UInt64,
        modelContextSize: Int?,
        quotaBefore: FoundationModelsBenchQuotaSnapshot?,
        quotaAfter: FoundationModelsBenchQuotaSnapshot?,
        startedAt: Date,
        endedAt: Date,
        environment: EnvironmentSnapshot,
        trials: [FoundationModelsBenchTrialResult],
        failures: [FoundationModelsBenchFailure],
        scenarios: [FoundationModelsBenchScenario]
    ) {
        self.suite = suite
        self.model = model
        self.warmupCount = warmupCount
        self.repetitions = repetitions
        self.sampleLimit = sampleLimit
        self.sessionMode = sessionMode
        self.reasoningLevel = reasoningLevel
        self.fallbackMode = fallbackMode
        self.connectivity = connectivity
        self.randomizedOrder = randomizedOrder
        self.randomSeed = randomSeed
        self.modelContextSize = modelContextSize
        self.quotaBefore = quotaBefore
        self.quotaAfter = quotaAfter
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.environment = environment
        self.trials = trials
        self.failures = failures
        self.summaries = scenarios.map { scenario in
            FoundationModelsBenchScenarioSummary(
                scenario: scenario,
                trials: trials.filter { $0.scenarioID == scenario.id },
                failureCount: failures.count(where: { $0.scenarioID == scenario.id })
            )
        }
    }
}
