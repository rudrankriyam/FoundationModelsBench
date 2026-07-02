import Foundation
import FoundationModels
import FoundationModelsKit

actor FoundationModelsBenchToolRecorder {
    private var calls: [FoundationModelsBenchToolCall] = []

    func record(_ call: FoundationModelsBenchToolCall) {
        calls.append(call)
    }

    func reset() {
        calls.removeAll(keepingCapacity: true)
    }

    func snapshot() -> [FoundationModelsBenchToolCall] {
        calls
    }
}

@Generable
struct KnowledgeLookupArguments: RuntimeCompatibleGenerable {
    @Guide(description: "The exact topic requested by the user")
    let topic: String

    @Guide(description: "The exact source ID requested by the user")
    let sourceID: String
}

struct KnowledgeLookupTool: Tool {
    let name = "lookupKnowledge"
    let description = "Returns a short trusted explanation for a topic and source ID."
    let recorder: FoundationModelsBenchToolRecorder

    func call(arguments: KnowledgeLookupArguments) async throws -> String {
        await recorder.record(
            FoundationModelsBenchToolCall(
                name: name,
                arguments: [
                    "topic": .string(arguments.topic),
                    "sourceID": .string(arguments.sourceID)
                ]
            )
        )

        let normalized = arguments.topic.lowercased()
        let fact: String
        switch normalized {
        case "mitochondria":
            fact = "Mitochondria convert nutrients into usable cellular energy."
        case "plate tectonics":
            fact = "Earth's surface is divided into moving plates whose interactions shape crust."
        case "compound interest":
            fact = "Compound interest earns interest on both principal and accumulated interest."
        case "photosynthesis":
            fact = "Photosynthesis uses light energy to turn carbon dioxide and water into sugars."
        case "binary search":
            fact = "Binary search repeatedly halves a sorted collection to locate a target."
        default:
            fact = "No trusted fact is available for this topic."
        }
        return "[\(arguments.sourceID)] \(fact)"
    }
}

@Generable
struct ExerciseSubstitutionArguments: RuntimeCompatibleGenerable {
    @Guide(description: "The exact exercise that cannot be performed")
    let unavailableExercise: String

    @Guide(description: "The exact user limitation")
    let limitation: String

    @Guide(description: "The exact available equipment")
    let equipment: String
}

struct ExerciseCatalogTool: Tool {
    let name = "findExerciseSubstitute"
    let description =
        "Returns one exercise substitute matching a limitation and available equipment."
    let recorder: FoundationModelsBenchToolRecorder

    func call(arguments: ExerciseSubstitutionArguments) async throws -> String {
        await recorder.record(
            FoundationModelsBenchToolCall(
                name: name,
                arguments: [
                    "unavailableExercise": .string(arguments.unavailableExercise),
                    "limitation": .string(arguments.limitation),
                    "equipment": .string(arguments.equipment)
                ]
            )
        )

        let key = arguments.unavailableExercise.lowercased()
        switch key {
        case "barbell squat":
            return "goblet squat"
        case "running":
            return "cycling"
        case "pull-up":
            return "band row"
        case "push-up":
            return "dumbbell floor press"
        case "box jump":
            return "reverse lunge"
        default:
            return "No compatible substitute found."
        }
    }
}

struct FoundationModelsBenchSessionBundle: Sendable {
    let session: LanguageModelSession
    let recorder: FoundationModelsBenchToolRecorder
    let mockWorld: FoundationModelsBenchMockPersonalOrganizerWorld?
}

struct FoundationModelsBenchToolRuntime: Sendable {
    let tools: [any Tool]
    let mockWorld: FoundationModelsBenchMockPersonalOrganizerWorld?
}

func foundationModelsBenchToolRuntime(
    for toolSet: FoundationModelsBenchToolSet,
    recorder: FoundationModelsBenchToolRecorder
) -> FoundationModelsBenchToolRuntime {
    switch toolSet {
    case .none:
        return FoundationModelsBenchToolRuntime(tools: [], mockWorld: nil)
    case .knowledge:
        return FoundationModelsBenchToolRuntime(
            tools: [KnowledgeLookupTool(recorder: recorder)],
            mockWorld: nil
        )
    case .exerciseCatalog:
        return FoundationModelsBenchToolRuntime(
            tools: [ExerciseCatalogTool(recorder: recorder)],
            mockWorld: nil
        )
    case .personalOrganizer:
        let world = FoundationModelsBenchMockPersonalOrganizerWorld()
        return FoundationModelsBenchToolRuntime(
            tools: [
                FoundationModelsBenchSearchContactsTool(world: world, recorder: recorder),
                FoundationModelsBenchListRemindersTool(world: world, recorder: recorder),
                FoundationModelsBenchCreateReminderTool(world: world, recorder: recorder)
            ],
            mockWorld: world
        )
    }
}
