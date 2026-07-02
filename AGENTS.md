# AGENTS.md

Guidance for agents working in FoundationModelsBench.

## Product

Foundation Models Bench is an open evaluation suite for Apple's Foundation Models
ecosystem. It focuses on on-device Apple Intelligence models, Private Cloud Compute,
and compatible provider adapters.

The repository should feel like an industry benchmark: reproducible, auditable,
conservative in its claims, and careful about what counts as publishable evidence.

## Toolchain

- Swift 6.2
- Xcode 26+ for the core package
- Xcode 27 for PCC and Apple Evaluations replay work
- Deployment targets: iOS 26.0+, macOS 26.0+, visionOS 26.0+

Keep OS 26 compatibility unless a file is explicitly compiler- and availability-gated.

## Validation

```bash
swift test
swift run foundation-models-bench list

xcodebuild \
  -project FoundationModelsBenchDeviceRunner/FoundationModelsBenchDeviceRunner.xcodeproj \
  -scheme FoundationModelsBenchDeviceRunner \
  -destination 'generic/platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Use Xcode 27 for `Evaluations` package validation.

## Architecture

- `Sources/FoundationModelsBenchCore`: scenarios, runner, deterministic graders,
  mocked agent worlds, metrics, environment capture, and reports.
- `Sources/FoundationModelsBenchCLI`: SwiftPM runner for official on-device Mac runs.
- `FoundationModelsBenchDeviceRunner`: signed iOS/macOS app runner for physical
  device and PCC runs.
- `Evaluations`: macOS 27 recorded-result replay into `.xcevalresult` artifacts.
- `Results`: curated JSON and Markdown benchmark outputs.
- `docs`: methodology, PCC notes, device matrix, research notes, and evaluation notes.

## Benchmark Rules

- Keep quality, safety, performance, and failures as separate report fields.
- Prefer deterministic checks over LLM judges.
- Prompt pass requires every deterministic check to pass.
- Throughput uses output tokens and decode duration only.
- Do not call stream snapshot gaps inter-token latency.
- Preserve measured failures in reports.
- Include OS build, thermal state, Low Power Mode, timestamp, model route, and commit.
- PCC results are service measurements, not device inference measurements.
- Agentic tools must use synthetic, resettable worlds and must not touch user data.
- Never publish Simulator output as benchmark evidence.
- Do not add migration aliases for removed public names.

## Scenario Rules

New scenarios need:

- Synthetic fixtures with clear provenance.
- Deterministic checks or explicitly marked subjective replay.
- Tests for grading behavior.
- Stable sample IDs.
- Documentation when they require OS 27, PCC, tools, visual input, or network state.

Read `docs/METHODOLOGY.md` before changing metrics, result schema, or official result
policy.
