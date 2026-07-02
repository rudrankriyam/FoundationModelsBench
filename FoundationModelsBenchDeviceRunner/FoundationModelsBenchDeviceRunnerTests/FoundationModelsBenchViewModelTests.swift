@testable import FoundationModelsBenchDeviceRunner
import FoundationModelsBenchCore
import XCTest

@MainActor
final class FoundationModelsBenchViewModelTests: XCTestCase {
    func testSuiteChangesApplySuiteSampleDefaults() {
        let viewModel = FoundationModelsBenchViewModel()

        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 1)

        viewModel.selectedSuite = .full
        XCTAssertTrue(viewModel.useAllSamples)
        XCTAssertNil(viewModel.makeConfiguration().sampleLimit)

        viewModel.useAllSamples = false
        viewModel.samplesPerScenario = 3
        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 3)

        viewModel.selectedSuite = .quick
        XCTAssertFalse(viewModel.useAllSamples)
        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 1)
    }
}
