import FoundationModelsBenchCore
import Evaluations
import FoundationModels

@available(macOS 27.0, *)
public typealias FoundationModelsBenchFinalStateProvider = @Sendable (
  FoundationModelsBenchEvaluationSample
) async throws -> FoundationModelsBenchStateSnapshot?

@available(macOS 27.0, *)
public enum FoundationModelsBenchEvaluationsAdapter {
  public static let promptPassMetric = Metric("FoundationModelsBench Prompt Pass")
  public static let constraintScoreMetric = Metric("FoundationModelsBench Constraint Score")
  public static let toolCallsPassMetric = Metric("FoundationModelsBench Tool Calls Pass")
  public static let toolCallsPercentageMetric = Metric("FoundationModelsBench Tool Calls Percentage")

  public static func samples(
    for scenario: FoundationModelsBenchScenario
  ) throws -> [FoundationModelsBenchEvaluationSample] {
    let schema: GenerationSchema?
    switch scenario.outputMode {
    case .text:
      schema = nil
    case .guided(let foundationModelsBenchSchema):
      schema = try FoundationModelsBenchSchemaFactory.make(foundationModelsBenchSchema)
    }

    return try scenario.samples.map { sample in
      FoundationModelsBenchEvaluationSample(
        recordID: sample.id,
        prompt: try foundationModelsBenchPrompt(for: sample),
        instructions: Instructions(scenario.instructions),
        generationSchema: schema,
        expectations: trajectoryExpectation(for: sample.checks)
      )
    }
  }

  public static func promptPassEvaluator(
    for scenario: FoundationModelsBenchScenario,
    finalStateProvider: FoundationModelsBenchFinalStateProvider? = nil
  ) -> Evaluator<FoundationModelsBenchEvaluationSample> {
    let checks = checksBySampleID(scenario)
    return Evaluator { input, subject in
      guard let sampleChecks = checks[input.recordID] else {
        return promptPassMetric.ignore(rationale: "Missing FoundationModelsBench sample metadata.")
      }
      let finalState = try await finalStateProvider?(input)
      if requiresFinalState(sampleChecks), finalState == nil {
        return promptPassMetric.ignore(
          rationale: "Final state was not supplied for this stateful sample."
        )
      }
      let grade = FoundationModelsBenchGrader.grade(
        response: subject.value,
        checks: sampleChecks,
        toolCalls: subject.foundationModelsBenchToolCalls,
        finalState: finalState
      )
      return grade.promptPassed
        ? promptPassMetric.passing()
        : promptPassMetric.failing(rationale: failedCheckRationale(grade))
    }
  }

  public static func constraintScoreEvaluator(
    for scenario: FoundationModelsBenchScenario,
    finalStateProvider: FoundationModelsBenchFinalStateProvider? = nil
  ) -> Evaluator<FoundationModelsBenchEvaluationSample> {
    let checks = checksBySampleID(scenario)
    return Evaluator { input, subject in
      guard let sampleChecks = checks[input.recordID] else {
        return constraintScoreMetric.ignore(
          rationale: "Missing FoundationModelsBench sample metadata."
        )
      }
      let finalState = try await finalStateProvider?(input)
      if requiresFinalState(sampleChecks), finalState == nil {
        return constraintScoreMetric.ignore(
          rationale: "Final state was not supplied for this stateful sample."
        )
      }
      let grade = FoundationModelsBenchGrader.grade(
        response: subject.value,
        checks: sampleChecks,
        toolCalls: subject.foundationModelsBenchToolCalls,
        finalState: finalState
      )
      return constraintScoreMetric.scoring(
        grade.score,
        rationale: failedCheckRationale(grade)
      )
    }
  }

  public static func toolCallEvaluator(
    for scenario: FoundationModelsBenchScenario
  ) -> ToolCallEvaluator<FoundationModelsBenchEvaluationSample>? {
    guard scenario.samples.contains(where: { trajectoryExpectation(for: $0.checks) != nil })
    else {
      return nil
    }
    return ToolCallEvaluator(
      allPass: toolCallsPassMetric,
      percentagePass: toolCallsPercentageMetric
    )
  }

  static func trajectoryExpectation(
    for checks: [FoundationModelsBenchCheck]
  ) -> TrajectoryExpectation? {
    var unorderedToolNames: [String] = []
    var orderedToolNames: [String] = []
    var disallowedToolNames: [String] = []
    var allowsAdditionalToolCalls = true
    var argumentsByTool: [String: [ArgumentMatcher]] = [:]

    for check in checks {
      switch check {
      case .toolCalled(let name):
        if !unorderedToolNames.contains(name) {
          unorderedToolNames.append(name)
        }
      case .toolArgumentEquals(let tool, let argument, let value):
        if !unorderedToolNames.contains(tool) {
          unorderedToolNames.append(tool)
        }
        argumentsByTool[tool, default: []].append(
          .exact(argumentName: argument, value: argumentValue(value))
        )
      case .toolArgumentContains(let tool, let argument, let value):
        if !unorderedToolNames.contains(tool) {
          unorderedToolNames.append(tool)
        }
        argumentsByTool[tool, default: []].append(
          .contains(argumentName: argument, substring: value)
        )
      case .toolCallSequence(let names, let allowsAdditionalCalls):
        orderedToolNames = names
        allowsAdditionalToolCalls = allowsAdditionalCalls
      case .toolNotCalled(let name):
        if !disallowedToolNames.contains(name) {
          disallowedToolNames.append(name)
        }
      default:
        break
      }
    }

    unorderedToolNames.removeAll { orderedToolNames.contains($0) }
    guard !orderedToolNames.isEmpty || !unorderedToolNames.isEmpty || !disallowedToolNames.isEmpty
    else {
      return nil
    }
    let ordered = orderedToolNames.map { name in
      ToolExpectation(name, arguments: argumentsByTool[name] ?? [])
    }
    let unordered = unorderedToolNames.map { name in
      ToolExpectation(name, arguments: argumentsByTool[name] ?? [])
    }
    let disallowed = disallowedToolNames.map { ToolExpectation($0) }
    var expectation = TrajectoryExpectation(
      ordered: ordered,
      unordered: unordered,
      allowsAdditionalToolCalls: allowsAdditionalToolCalls
    )
    expectation.disallowed = disallowed
    return expectation
  }

  private static func checksBySampleID(
    _ scenario: FoundationModelsBenchScenario
  ) -> [String: [FoundationModelsBenchCheck]] {
    Dictionary(uniqueKeysWithValues: scenario.samples.map { ($0.id, $0.checks) })
  }

  private static func requiresFinalState(_ checks: [FoundationModelsBenchCheck]) -> Bool {
    checks.contains { check in
      switch check {
      case .stateEquals, .stateContains:
        true
      default:
        false
      }
    }
  }

  private static func argumentValue(_ value: FoundationModelsBenchJSONValue) -> ArgumentValue {
    switch value {
    case .string(let value):
      .string(value)
    case .integer(let value):
      .int(value)
    case .number(let value):
      .double(value)
    case .boolean(let value):
      .bool(value)
    }
  }

  private static func failedCheckRationale(_ grade: FoundationModelsBenchGrade) -> String? {
    let failures = grade.checks.filter { !$0.passed }.map(\.label)
    return failures.isEmpty ? nil : failures.joined(separator: "; ")
  }
}

@available(macOS 27.0, *)
extension ModelSubject where Value == String {
  fileprivate var foundationModelsBenchToolCalls: [FoundationModelsBenchToolCall] {
    toolCalls.compactMap { call in
      guard case .structure(let properties, _) = call.arguments.kind else {
        return nil
      }
      let arguments = properties.compactMapValues(\.foundationModelsBenchJSONValue)
      return FoundationModelsBenchToolCall(name: call.toolName, arguments: arguments)
    }
  }
}

@available(macOS 27.0, *)
extension GeneratedContent {
  fileprivate var foundationModelsBenchJSONValue: FoundationModelsBenchJSONValue? {
    switch kind {
    case .string(let value):
      return .string(value)
    case .number(let value):
      if value.rounded() == value {
        return .integer(Int(value))
      }
      return .number(value)
    case .bool(let value):
      return .boolean(value)
    case .null, .array, .structure:
      return nil
    @unknown default:
      return nil
    }
  }
}
