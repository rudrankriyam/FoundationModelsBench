import FoundationModelsBenchCore
import Evaluations
import Foundation
import FoundationModels

@available(macOS 27.0, *)
public enum FoundationModelsBenchSubjectiveJudge: Sendable {
  case privateCloudCompute

  public var identifier: String {
    switch self {
    case .privateCloudCompute:
      "privateCloudCompute"
    }
  }

  public var displayName: String {
    switch self {
    case .privateCloudCompute:
      "PrivateCloudComputeLanguageModel"
    }
  }

  func makeLanguageModel() throws -> any LanguageModel {
    switch self {
    case .privateCloudCompute:
      #if compiler(>=6.4)
        let model = PrivateCloudComputeLanguageModel()
        if case .unavailable(let reason) = model.availability {
          throw FoundationModelsBenchSubjectiveQualityError.judgeUnavailable(
            displayName,
            String(describing: reason)
          )
        }
        return model
      #else
        throw FoundationModelsBenchSubjectiveQualityError.judgeRequiresXcode27(displayName)
      #endif
    }
  }
}

@available(macOS 27.0, *)
public struct FoundationModelsBenchSubjectiveQualityEvaluation: Evaluation {
  public static let helpfulness = ScoreDimension(
    "FoundationModelsBench Subjective Helpfulness",
    description: "Whether the response is useful for the app-shaped task.",
    scale: .numeric([
      4.0: "Directly useful and actionable",
      3.0: "Mostly useful with minor gaps",
      2.0: "Partly useful but noticeably weak",
      1.0: "Not useful for the task"
    ])
  )

  public static let clarity = ScoreDimension(
    "FoundationModelsBench Subjective Clarity",
    description: "Whether the response is easy to understand without extra work.",
    scale: .numeric([
      4.0: "Clear, concise, and well organized",
      3.0: "Understandable with minor rough edges",
      2.0: "Hard to follow in places",
      1.0: "Confusing or poorly organized"
    ])
  )

  public static let completeness = ScoreDimension(
    "FoundationModelsBench Subjective Completeness",
    description: "Whether the response covers the important parts of the request.",
    scale: .numeric([
      4.0: "Covers the task fully",
      3.0: "Covers the main task with small omissions",
      2.0: "Misses important parts",
      1.0: "Does not meaningfully complete the task"
    ])
  )

  public let dataset: ArrayLoader<FoundationModelsBenchEvaluationSample>
  public let run: FoundationModelsBenchRecordedRun
  public let judge: FoundationModelsBenchSubjectiveJudge

  private let recordsByID: [String: FoundationModelsBenchEvaluationRecord]
  private let judgeModel: any LanguageModel

  public init(
    run: FoundationModelsBenchRecordedRun,
    judge: FoundationModelsBenchSubjectiveJudge = .privateCloudCompute
  ) throws {
    let records = Self.eligibleRecords(in: run)
    guard !records.isEmpty else {
      throw FoundationModelsBenchSubjectiveQualityError.noEligibleSamples
    }

    self.run = run
    self.judge = judge
    judgeModel = try judge.makeLanguageModel()
    recordsByID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
    dataset = ArrayLoader(
      samples: records.map { record in
        FoundationModelsBenchEvaluationSample(
          recordID: record.id,
          prompt: Prompt(record.prompt),
          instructions: Instructions(record.instructions),
          expectations: FoundationModelsBenchEvaluationsAdapter.trajectoryExpectation(
            for: record.checks
          )
        )
      }
    )
  }

  public static func eligibleRecords(
    in run: FoundationModelsBenchRecordedRun
  ) -> [FoundationModelsBenchEvaluationRecord] {
    run.records.filter { record in
      guard
        record.executionSucceeded,
        record.safetyExpectation == nil,
        let response = record.response,
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        return false
      }

      let grade = FoundationModelsBenchGrader.grade(
        response: response,
        checks: record.checks,
        toolCalls: record.toolCalls,
        finalState: record.finalState
      )
      return grade.promptPassed
    }
  }

  public func subject(
    from sample: FoundationModelsBenchEvaluationSample
  ) async throws -> ModelSubject<String> {
    let record = try record(for: sample)
    return ModelSubject(value: record.response ?? "")
  }

  public var evaluators: Evaluators {
    let prompt = ModelJudgePrompt<FoundationModelsBenchEvaluationSample>(
      instructions: Self.judgeInstructions,
      reference: { [recordsByID] sample, _ in
        guard let record = recordsByID[sample.recordID] else {
          return [:]
        }
        return Self.reference(for: record)
      }
    )
    let dimensions: [ScoreDimension] = [
      Self.helpfulness,
      Self.clarity,
      Self.completeness
    ]
    let evaluator = ModelJudgeEvaluator<FoundationModelsBenchEvaluationSample>(
      judge: judgeModel,
      dimensions: dimensions,
      prompt: prompt
    )
    return [evaluator]
  }

  public func aggregateMetrics(using aggregator: inout MetricsAggregator) {
    aggregator.group("Subjective Quality") { group in
      group.computeMean(of: Self.helpfulness.metric)
      group.computeMean(of: Self.clarity.metric)
      group.computeMean(of: Self.completeness.metric)
    }
  }

  private func record(
    for sample: FoundationModelsBenchEvaluationSample
  ) throws -> FoundationModelsBenchEvaluationRecord {
    guard let record = recordsByID[sample.recordID] else {
      throw FoundationModelsBenchSubjectiveQualityError.missingRecord(sample.recordID)
    }
    return record
  }

  private static func reference(
    for record: FoundationModelsBenchEvaluationRecord
  ) -> [String: String] {
    [
      "Scenario": record.scenarioTitle,
      "Scenario ID": record.scenarioID,
      "Sample ID": record.sampleID,
      "Requested model": record.requestedModel,
      "Executed model": record.executedModel,
      "Deterministic checks": record.checks.map(\.label).joined(separator: "\n")
    ]
  }

  private static let judgeInstructions = """
    You are judging recorded FoundationModelsBench responses for subjective quality.

    Score only the response shown for the requested app-shaped task. The deterministic \
    FoundationModelsBench grader has already checked exact constraints, structured values, tool \
    trajectory, safety gates, and final state where applicable. Do not re-score those \
    hard requirements unless they affect the subjective usefulness of the answer.

    Prefer concise, grounded, task-completing responses. Do not reward verbosity by \
    itself. Return a score for every dimension and a short rationale.
    """
}

@available(macOS 27.0, *)
public enum FoundationModelsBenchSubjectiveQualityError: LocalizedError {
  case noEligibleSamples
  case missingRecord(String)
  case judgeRequiresXcode27(String)
  case judgeUnavailable(String, String)

  public var errorDescription: String? {
    switch self {
    case .noEligibleSamples:
      """
      No samples are eligible for subjective judging. FoundationModelsBench only sends successful, \
      deterministic-passing, non-safety responses to the model judge.
      """
    case .missingRecord(let id):
      "The subjective evaluation sample does not map to an FoundationModelsBench record: \(id)."
    case .judgeRequiresXcode27(let judge):
      "\(judge) requires the Xcode 27 SDK."
    case .judgeUnavailable(let judge, let reason):
      "\(judge) is unavailable: \(reason)"
    }
  }
}
