import Foundation

public struct FoundationModelsBenchStateSnapshot: Codable, Equatable, Sendable {
    public let values: [String: FoundationModelsBenchJSONValue]

    public init(values: [String: FoundationModelsBenchJSONValue]) {
        self.values = values
    }
}
