import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
struct FoundationModelsBenchListRemindersArguments: RuntimeCompatibleGenerable {
    @Guide(description: "The exact proposed reminder title")
    let title: String
}

struct FoundationModelsBenchListRemindersTool: Tool {
    let name = "listReminders"
    let description =
        "Lists matching reminders in the benchmark's synthetic store before creation."
    let world: FoundationModelsBenchMockPersonalOrganizerWorld
    let recorder: FoundationModelsBenchToolRecorder

    func call(arguments: FoundationModelsBenchListRemindersArguments) async throws -> String {
        await recorder.record(
            FoundationModelsBenchToolCall(
                name: name,
                arguments: ["title": .string(arguments.title)]
            )
        )

        let reminders = await world.reminders(matchingTitle: arguments.title)
        guard !reminders.isEmpty else {
            return "status=ok; matches=0"
        }
        let records = reminders.map {
            "id=\($0.id); title=\($0.title); dueDate=\($0.dueDate); notes=\($0.notes)"
        }.joined(separator: "\n")
        return "status=ok; matches=\(reminders.count)\n\(records)"
    }
}
