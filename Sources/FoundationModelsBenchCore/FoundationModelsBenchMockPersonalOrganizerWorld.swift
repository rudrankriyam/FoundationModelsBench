import Foundation

actor FoundationModelsBenchMockPersonalOrganizerWorld {
    enum ContactSearchOutcome: Sendable {
        case results([FoundationModelsBenchPersonalOrganizerContact])
        case transientFailure
    }

    enum ReminderCreationOutcome: Sendable {
        case created(FoundationModelsBenchPersonalOrganizerReminder)
        case duplicate(FoundationModelsBenchPersonalOrganizerReminder)
        case hardFailure
    }

    private var contacts: [FoundationModelsBenchPersonalOrganizerContact]
    private var reminders: [FoundationModelsBenchPersonalOrganizerReminder]
    private var remainingSearchFailures: Int
    private var remainingCreateFailures: Int

    init() {
        let fixture = FoundationModelsBenchPersonalOrganizerFixture.fixture(for: "personal-organizer-001")
        contacts = fixture.contacts
        reminders = fixture.reminders
        remainingSearchFailures = fixture.transientSearchFailures
        remainingCreateFailures = fixture.hardCreateFailures
    }

    func reset(for sampleID: String = "personal-organizer-001") {
        let fixture = FoundationModelsBenchPersonalOrganizerFixture.fixture(for: sampleID)
        contacts = fixture.contacts
        reminders = fixture.reminders
        remainingSearchFailures = fixture.transientSearchFailures
        remainingCreateFailures = fixture.hardCreateFailures
    }

    func contacts(matching query: String) -> ContactSearchOutcome {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return .results([])
        }

        if remainingSearchFailures > 0 {
            remainingSearchFailures -= 1
            return .transientFailure
        }

        let results = contacts.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || query.localizedCaseInsensitiveContains($0.name)
        }
        return .results(results)
    }

    func reminders(matchingTitle query: String) -> [FoundationModelsBenchPersonalOrganizerReminder] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return []
        }

        return reminders.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || query.localizedCaseInsensitiveContains($0.title)
        }
    }

    func createReminder(
        title: String,
        dueDate: String,
        notes: String
    ) -> ReminderCreationOutcome {
        if remainingCreateFailures > 0 {
            remainingCreateFailures -= 1
            return .hardFailure
        }

        if let duplicate = reminders.first(where: {
            $0.title.compare(title, options: [.caseInsensitive, .diacriticInsensitive])
                == .orderedSame && $0.dueDate == dueDate
        }) {
            return .duplicate(duplicate)
        }

        let reminder = FoundationModelsBenchPersonalOrganizerReminder(
            id: "reminder-\(reminders.count + 1)",
            title: title,
            dueDate: dueDate,
            notes: notes
        )
        reminders.append(reminder)
        return .created(reminder)
    }

    func snapshot() -> FoundationModelsBenchStateSnapshot {
        var values: [String: FoundationModelsBenchJSONValue] = [
            "reminders.count": .integer(reminders.count)
        ]
        if let latest = reminders.last {
            values["reminders.latest.id"] = .string(latest.id)
            values["reminders.latest.title"] = .string(latest.title)
            values["reminders.latest.dueDate"] = .string(latest.dueDate)
            values["reminders.latest.notes"] = .string(latest.notes)
        }
        return FoundationModelsBenchStateSnapshot(values: values)
    }
}
