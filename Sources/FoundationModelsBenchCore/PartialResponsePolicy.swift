import Foundation
import FoundationModels

enum FoundationModelsBenchPartialResponsePolicy {
    static func shouldPreserve(
        _ response: String,
        after error: LanguageModelSession.GenerationError
    ) -> Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && FoundationModelsBenchSafetyClassifier.outcome(for: error) == nil
    }
}
