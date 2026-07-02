import Foundation
import FoundationModelsBenchCore

struct RecordedRunInfo {
  let suite: String
  let model: String
  let warmupCount: Int
  let repetitions: Int
  let startedAt: Date
  let endedAt: Date
  let schema: String

  func dictionary(
    environment: EnvironmentInfo?,
    sourceName: String?
  ) -> [String: String] {
    var info = [
      "FoundationModelsBench Suite": suite,
      "FoundationModelsBench Model": model,
      "FoundationModelsBench Warmups": String(warmupCount),
      "FoundationModelsBench Repetitions": String(repetitions),
      "FoundationModelsBench Started": startedAt.formatted(.iso8601),
      "FoundationModelsBench Ended": endedAt.formatted(.iso8601),
      "FoundationModelsBench Source Schema": schema,
      "Evaluation Mode": "Recorded replay; no second model inference"
    ]
    if let sourceName {
      info["FoundationModelsBench Source File"] = sourceName
    }
    if let environment {
      info.merge(environment.dictionary) { _, new in new }
    }
    return info
  }
}

struct EnvironmentInfo {
  let deviceName: String?
  let systemName: String?
  let systemVersion: String?
  let systemBuild: String?
  let hardwareModel: String?
  let cpuModel: String?
  let foundationModelsBenchCommit: String?

  init(_ environment: EnvironmentSnapshot) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    foundationModelsBenchCommit = environment.foundationModelsBenchCommit
  }

  var dictionary: [String: String] {
    var values: [String: String] = [:]
    values["Device"] = deviceName
    values["System"] = [systemName, systemVersion]
      .compactMap(\.self)
      .joined(separator: " ")
    values["System Build"] = systemBuild
    values["Hardware Model"] = hardwareModel
    values["Chip"] = cpuModel
    values["FoundationModelsBench Commit"] = foundationModelsBenchCommit
    return values.filter { !$0.value.isEmpty }
  }
}
