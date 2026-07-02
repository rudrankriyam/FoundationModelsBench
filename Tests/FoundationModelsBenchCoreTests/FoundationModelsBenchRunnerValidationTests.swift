@testable import FoundationModelsBenchCore
import Testing

struct FoundationModelsBenchRunnerValidationTests {
    @Test
    func runnerRejectsUnknownSampleIDsBeforeExecution() async {
        let scenario = FoundationModelsBenchScenarioCatalog.taskCapture
        let runner = FoundationModelsBenchRunner(
            configuration: FoundationModelsBenchRunConfiguration(
                scenarios: [scenario],
                warmupCount: 0,
                repetitions: 1,
                sampleIDs: [scenario.samples[0].id, "missing-sample"],
                randomizeOrder: false
            )
        )

        do {
            _ = try await runner.run()
            Issue.record("Expected unknown sample IDs to fail before execution.")
        } catch let error as FoundationModelsBenchRunner.Error {
            guard case .unknownSampleIDs(let sampleIDs) = error else {
                Issue.record("Expected an unknown sample ID error, got \(error).")
                return
            }
            #expect(sampleIDs == ["missing-sample"])
        } catch {
            Issue.record("Expected an FoundationModelsBenchRunner error, got \(error).")
        }
    }

    @Test
    func runnerRejectsConfigurationsWithNoSamples() async {
        let runner = FoundationModelsBenchRunner(
            configuration: FoundationModelsBenchRunConfiguration(
                scenarios: [],
                warmupCount: 0,
                repetitions: 1,
                randomizeOrder: false
            )
        )

        do {
            _ = try await runner.run()
            Issue.record("Expected an empty configuration to fail before execution.")
        } catch let error as FoundationModelsBenchRunner.Error {
            guard case .noSamplesSelected = error else {
                Issue.record("Expected a no samples selected error, got \(error).")
                return
            }
        } catch {
            Issue.record("Expected an FoundationModelsBenchRunner error, got \(error).")
        }
    }
}
