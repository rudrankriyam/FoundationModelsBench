import FoundationModelsBenchCore
import SwiftUI

struct FoundationModelsBenchScenarioListView: View {
    let scenarios: [FoundationModelsBenchScenario]

    var body: some View {
        DisclosureGroup("Workloads (\(scenarios.count))") {
            ForEach(scenarios) { scenario in
                FoundationModelsBenchScenarioRow(scenario: scenario)
            }
        }
    }
}
