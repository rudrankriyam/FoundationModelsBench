import FoundationModelsBenchCore
import Foundation

public struct FoundationModelsBenchRecordedRun: Sendable {
  public let info: [String: String]
  public let records: [FoundationModelsBenchEvaluationRecord]

  public init(
    info: [String: String],
    records: [FoundationModelsBenchEvaluationRecord]
  ) {
    self.info = info
    self.records = records
  }
}

public struct FoundationModelsBenchEvaluationRecord: Sendable {
  public let id: String
  public let scenarioID: String
  public let scenarioTitle: String
  public let sampleID: String
  public let prompt: String
  public let instructions: String
  public let checks: [FoundationModelsBenchCheck]
  public let response: String?
  public let toolCalls: [FoundationModelsBenchToolCall]
  public let finalState: FoundationModelsBenchStateSnapshot?
  public let safetyExpectation: FoundationModelsBenchSafetyExpectation?
  public let safetyOutcome: FoundationModelsBenchSafetyOutcome
  public let iteration: Int
  public let requestedModel: String
  public let executedModel: String
  public let failureKind: String?
  public let failureMessage: String?
  public let duration: TimeInterval?
  public let timeToFirstToken: TimeInterval?
  public let outputTokensPerSecond: Double?
  public let peakObservedResidentMemoryBytes: UInt64?

  public init(
    id: String = UUID().uuidString,
    scenarioID: String,
    scenarioTitle: String,
    sampleID: String,
    prompt: String,
    instructions: String,
    checks: [FoundationModelsBenchCheck],
    response: String?,
    toolCalls: [FoundationModelsBenchToolCall] = [],
    finalState: FoundationModelsBenchStateSnapshot? = nil,
    safetyExpectation: FoundationModelsBenchSafetyExpectation? = nil,
    safetyOutcome: FoundationModelsBenchSafetyOutcome = .notApplicable,
    iteration: Int = 1,
    requestedModel: String = "unknown",
    executedModel: String = "unknown",
    failureKind: String? = nil,
    failureMessage: String? = nil,
    duration: TimeInterval? = nil,
    timeToFirstToken: TimeInterval? = nil,
    outputTokensPerSecond: Double? = nil,
    peakObservedResidentMemoryBytes: UInt64? = nil
  ) {
    self.id = id
    self.scenarioID = scenarioID
    self.scenarioTitle = scenarioTitle
    self.sampleID = sampleID
    self.prompt = prompt
    self.instructions = instructions
    self.checks = checks
    self.response = response
    self.toolCalls = toolCalls
    self.finalState = finalState
    self.safetyExpectation = safetyExpectation
    self.safetyOutcome = safetyOutcome
    self.iteration = iteration
    self.requestedModel = requestedModel
    self.executedModel = executedModel
    self.failureKind = failureKind
    self.failureMessage = failureMessage
    self.duration = duration
    self.timeToFirstToken = timeToFirstToken
    self.outputTokensPerSecond = outputTokensPerSecond
    self.peakObservedResidentMemoryBytes = peakObservedResidentMemoryBytes
  }

  public var executionSucceeded: Bool {
    failureMessage == nil
  }
}

public enum FoundationModelsBenchRecordedRunLoader {
  public static func load(from url: URL) throws -> FoundationModelsBenchRecordedRun {
    try decode(
      Data(contentsOf: url),
      sourceName: url.lastPathComponent
    )
  }

  public static func decode(
    _ data: Data,
    sourceName: String? = nil
  ) throws -> FoundationModelsBenchRecordedRun {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      let result = try decoder.decode(FoundationModelsBenchRunResult.self, from: data)
      return currentRun(result, sourceName: sourceName)
    } catch {
      throw FoundationModelsBenchRecordedRunError.invalidDocument(
        schemaError: error.localizedDescription
      )
    }
  }

  private static func currentRun(
    _ result: FoundationModelsBenchRunResult,
    sourceName: String?
  ) -> FoundationModelsBenchRecordedRun {
    let scenarios = Dictionary(
      uniqueKeysWithValues: FoundationModelsBenchScenarioCatalog.all.map { ($0.id, $0) }
    )
    let measuredFailures = result.failures.filter {
      $0.scenarioID != "__warmup__"
    }
    let records =
      result.trials.map { currentRecord($0, scenarios: scenarios) }
      + measuredFailures.map {
        currentFailureRecord(
          $0,
          model: result.model,
          scenarios: scenarios
        )
      }

    return FoundationModelsBenchRecordedRun(
      info: RecordedRunInfo(
        suite: result.suite.rawValue,
        model: result.model.rawValue,
        warmupCount: result.warmupCount,
        repetitions: result.repetitions,
        startedAt: result.startedAt,
        endedAt: result.endedAt,
        schema: "current"
      ).dictionary(
        environment: EnvironmentInfo(result.environment),
        sourceName: sourceName
      ),
      records: records
    )
  }

  private static func currentRecord(
    _ trial: FoundationModelsBenchTrialResult,
    scenarios: [String: FoundationModelsBenchScenario]
  ) -> FoundationModelsBenchEvaluationRecord {
    let scenario = scenarios[trial.scenarioID]
    return FoundationModelsBenchEvaluationRecord(
      id: trial.id.uuidString,
      scenarioID: trial.scenarioID,
      scenarioTitle: trial.scenarioTitle,
      sampleID: trial.sample.id,
      prompt: trial.sample.prompt,
      instructions: scenario?.instructions ?? "",
      checks: trial.sample.checks,
      response: trial.response,
      toolCalls: trial.toolCalls,
      finalState: trial.finalState,
      safetyExpectation: trial.sample.safetyExpectation,
      safetyOutcome: trial.safetyOutcome,
      iteration: trial.iteration,
      requestedModel: trial.requestedModel.rawValue,
      executedModel: trial.executedModel.rawValue,
      duration: trial.metrics.duration,
      timeToFirstToken: trial.metrics.timeToFirstToken,
      outputTokensPerSecond: trial.metrics.outputTokensPerSecond,
      peakObservedResidentMemoryBytes: trial.metrics
        .peakObservedResidentMemoryBytes
    )
  }

  private static func currentFailureRecord(
    _ failure: FoundationModelsBenchFailure,
    model: FoundationModelsBenchModel,
    scenarios: [String: FoundationModelsBenchScenario]
  ) -> FoundationModelsBenchEvaluationRecord {
    let scenario = scenarios[failure.scenarioID]
    let sample = scenario?.samples.first { $0.id == failure.sampleID }
    return FoundationModelsBenchEvaluationRecord(
      id: failure.id.uuidString,
      scenarioID: failure.scenarioID,
      scenarioTitle: scenario?.title ?? failure.scenarioID,
      sampleID: failure.sampleID,
      prompt: sample?.prompt
        ?? "Execution failed before prompt metadata was recorded.",
      instructions: scenario?.instructions ?? "",
      checks: sample?.checks ?? [],
      response: nil,
      toolCalls: failure.toolCalls ?? [],
      finalState: failure.finalState,
      safetyExpectation: sample?.safetyExpectation,
      safetyOutcome: safetyOutcome(forFailureKind: failure.kind),
      iteration: failure.iteration,
      requestedModel: model.rawValue,
      executedModel: model.rawValue,
      failureKind: failure.kind,
      failureMessage: failure.message
    )
  }

  private static func safetyOutcome(
    forFailureKind failureKind: String
  ) -> FoundationModelsBenchSafetyOutcome {
    switch failureKind {
    case "guardrail":
      .guardrailViolation
    case "refusal":
      .refusal
    default:
      .notApplicable
    }
  }

}

public enum FoundationModelsBenchRecordedRunError: LocalizedError {
  case invalidDocument(schemaError: String)

  public var errorDescription: String? {
    switch self {
    case .invalidDocument(let schemaError):
      """
      The file is not a supported FoundationModelsBench result.
      Schema error: \(schemaError)
      """
    }
  }
}
