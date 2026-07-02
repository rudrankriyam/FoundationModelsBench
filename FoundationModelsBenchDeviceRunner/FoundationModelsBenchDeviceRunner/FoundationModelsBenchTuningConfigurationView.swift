import FoundationModelsBenchCore
import SwiftUI

struct FoundationModelsBenchTuningConfigurationView: View {
    @Bindable var viewModel: FoundationModelsBenchViewModel

    var body: some View {
        Picker("Session", selection: $viewModel.selectedSessionMode) {
            ForEach(FoundationModelsBenchSessionMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }

        Picker("Connectivity", selection: $viewModel.selectedConnectivity) {
            ForEach(FoundationModelsBenchConnectivity.allCases) { connectivity in
                Text(connectivity.displayName).tag(connectivity)
            }
        }

        if viewModel.selectedModel == .privateCloudCompute {
            Picker("Reasoning", selection: $viewModel.selectedReasoningLevel) {
                ForEach(FoundationModelsBenchReasoningLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }

            Picker("Fallback", selection: $viewModel.selectedFallbackMode) {
                ForEach(FoundationModelsBenchFallbackMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        }

        Stepper(
            "Warmups: \(viewModel.warmupCount)",
            value: $viewModel.warmupCount,
            in: 0...10
        )

        Stepper(
            "Measured runs: \(viewModel.repetitions)",
            value: $viewModel.repetitions,
            in: 1...50
        )

        Toggle("Use all samples", isOn: $viewModel.useAllSamples)

        if !viewModel.useAllSamples {
            Stepper(
                "Samples per workload: \(viewModel.samplesPerScenario)",
                value: $viewModel.samplesPerScenario,
                in: 1...25
            )
        }

        Toggle("Randomize order", isOn: $viewModel.randomizeOrder)
    }
}
