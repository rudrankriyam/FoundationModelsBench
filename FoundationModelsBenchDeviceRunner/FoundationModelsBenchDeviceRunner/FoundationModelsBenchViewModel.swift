import FoundationModelsBenchCore
import Observation
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
@Observable
final class FoundationModelsBenchViewModel {
    var selectedSuite: FoundationModelsBenchSuite = .quick {
        didSet {
            guard selectedSuite != oldValue else { return }
            applySampleDefaults(for: selectedSuite)
        }
    }
    var selectedModel: FoundationModelsBenchModel = .onDevice
    var selectedSessionMode: FoundationModelsBenchSessionMode = .cold
    var selectedReasoningLevel: FoundationModelsBenchReasoningLevel = .none
    var selectedFallbackMode: FoundationModelsBenchFallbackMode = .disabled
    var selectedConnectivity: FoundationModelsBenchConnectivity = .normal
    var warmupCount = 5
    var repetitions = 20
    var samplesPerScenario = 1
    var useAllSamples = false
    var randomizeOrder = true
    var randomSeed: UInt64 = 20_260_929
    var isRunning = false
    var result: FoundationModelsBenchRunResult?
    var errorMessage = ""
    var showError = false

    var selectedScenarios: [FoundationModelsBenchScenario] {
        FoundationModelsBenchScenarioCatalog.scenarios(for: selectedSuite)
    }

    func run() {
        guard !isRunning else { return }

        isRunning = true
        result = nil

        let configuration = makeConfiguration()

        Task {
            do {
                result = try await FoundationModelsBenchRunner(configuration: configuration).run()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRunning = false
        }
    }

    func makeConfiguration() -> FoundationModelsBenchRunConfiguration {
        FoundationModelsBenchRunConfiguration(
            suite: selectedSuite,
            model: selectedModel,
            warmupCount: warmupCount,
            repetitions: repetitions,
            sampleLimit: samplesPerScenario,
            useAllSamples: useAllSamples,
            sessionMode: selectedSessionMode,
            reasoningLevel: selectedReasoningLevel,
            fallbackMode: selectedFallbackMode,
            connectivity: selectedConnectivity,
            randomizeOrder: randomizeOrder,
            randomSeed: randomSeed
        )
    }

    func copyMarkdown() {
        guard let result else { return }
        let markdown = FoundationModelsBenchReport(result: result).markdown()

        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
        #else
            UIPasteboard.general.string = markdown
        #endif
    }

    private func applySampleDefaults(for suite: FoundationModelsBenchSuite) {
        if let sampleLimit = suite.defaultSampleLimit {
            samplesPerScenario = sampleLimit
            useAllSamples = false
        } else {
            useAllSamples = true
        }
    }
}
