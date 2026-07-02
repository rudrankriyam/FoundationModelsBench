# Foundation Models Bench

Foundation Models Bench is an open evaluation suite for Apple's Foundation Models
ecosystem. It measures deployment-shaped workloads across the on-device system model,
Private Cloud Compute, and Foundation Models-compatible provider adapters.

The benchmark is designed for reproducible, inspectable evidence rather than a single
leaderboard number. It reports quality, safety, tool behavior, latency, throughput,
failures, and environment metadata separately so a fast incorrect model does not look
good and a correct slow model does not hide its cost.

## Scope

Foundation Models Bench treats these tracks as first class:

| Track | Purpose | Valid runner |
| --- | --- | --- |
| On-device Foundation Models | Local Apple Intelligence model behavior on physical Apple hardware | SwiftPM CLI on Mac, signed device runner on iPhone/iPad |
| Private Cloud Compute | End-to-end service behavior through Apple's PCC model path | Signed app runner with PCC entitlement |
| Compatible provider adapters | Secondary baselines for providers that conform to the Foundation Models execution contract | Adapter-backed runner |

Third-party cloud models are useful comparison controls, but they are not the center
of the benchmark. The primary goal is to make Foundation Models and PCC results
credible, comparable, and reproducible.

## Design Principles

- **Separate quality from performance.** Prompt pass, constraint score, safety pass,
  latency, throughput, and failures are independent report fields.
- **Prefer deterministic grading.** The core benchmark uses exact checks, structured
  values, tool arguments, final-state assertions, and safety outcomes before any
  subjective judge is considered.
- **Preserve failures.** Warmup failures remain diagnostic; measured failures count
  against execution success.
- **Record the environment.** Results include device, hardware model, OS version,
  OS build, locale, thermal state, Low Power Mode, timestamp, model route, and commit.
- **Do not publish Simulator results.** Simulator output is useful for build and UI
  validation only.
- **Treat PCC as a service benchmark.** PCC numbers include network and server
  behavior. They are not device inference throughput.
- **Use synthetic fixtures.** Scenario inputs are reproducible and inspectable. The
  benchmark must not read user contacts, reminders, health data, documents, or other
  private data.

## Workloads

The starter corpus covers practical app-shaped tasks:

| Suite | What It Measures |
| --- | --- |
| Practical Quick | Representative subset for smoke checks and fast comparison |
| Practical Full | Fixed samples across parsing, summarization, classification, grounded QA, citation extraction, visual reasoning, and creative generation |
| Agentic Tools | Ordered tool calls, typed arguments, retry behavior, duplicate prevention, user-visible outcome, and final synthetic world state |
| Safety Guardrails | Expected responses, expected protection, explicit guardrail violations, refusals, false positives, and missed protection |
| Performance | Sustained generation, time to first token, decode speed, stream gaps, and memory observations |
| Context | Long-context retrieval, context utilization, and offline experiment labels |

Guided generation structure is not counted as semantic quality. The framework already
enforces decodable structure; Foundation Models Bench grades the values inside the
structured response.

## Metrics

Every measured trial records:

- End-to-end task success.
- Prompt-level pass.
- Constraint score.
- Safety outcome and critical safety failures.
- End-to-end duration.
- Time to first token.
- Decode duration.
- Output tokens per second.
- Output characters per second.
- Stream update count and maximum stream-update gap.
- Input, output, and reasoning token usage when exposed by the runtime.
- Context size and context utilization.
- Starting, ending, and peak observed resident memory.
- Starting, ending, and worst observed thermal state.
- Tool names, typed arguments, ordered trajectory, and final state.
- Requested model, executed model, and fallback reason.
- PCC quota state when available.

Scenario summaries report median, p90, mean, range, standard deviation, prompt pass,
constraint score, task success, and execution failure rate.

## Requirements

- Swift 6.2.
- Xcode 26 or newer for the OS 26-compatible core.
- Xcode 27 for OS 27 APIs, PCC experiments, and Apple Evaluations replay.
- macOS 26 or newer for the SwiftPM runner.
- iOS/iPadOS 26 or macOS 26 or newer for the signed device runner.
- Apple Intelligence enabled on supported physical hardware.
- PCC entitlement and provisioning for publishable Private Cloud Compute results.

## Quick Start

```bash
git clone https://github.com/rudrankriyam/FoundationModelsBench.git
cd FoundationModelsBench

swift test
swift run foundation-models-bench list
swift run foundation-models-bench --suite quick --model on-device
```

Path-independent launcher:

```bash
./foundation-models-bench --suite quick --model on-device
```

Export JSON and Markdown:

```bash
swift run foundation-models-bench --suite full \
  --warmups 5 \
  --repetitions 20 \
  --model on-device \
  --json Results/macbook-pro-macos27-on-device-full.json \
  --markdown Results/macbook-pro-macos27-on-device-full.md
```

Run one agentic sample with full tool/state evidence:

```bash
swift run foundation-models-bench --suite agentic \
  --sample personal-organizer-012 \
  --warmups 0 \
  --repetitions 1 \
  --no-randomize
```

Run the guardrail suite:

```bash
swift run foundation-models-bench --suite guardrails \
  --warmups 5 \
  --repetitions 20
```

## Private Cloud Compute

Do not use `swift run foundation-models-bench --model pcc` as publishable PCC
evidence. SwiftPM executables do not inherit a signed application target's managed
PCC entitlement.

For PCC, build and run the signed device runner:

```bash
xcodebuild \
  -project FoundationModelsBenchDeviceRunner/FoundationModelsBenchDeviceRunner.xcodeproj \
  -scheme FoundationModelsBenchDeviceRunner \
  -destination 'generic/platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

For publishable PCC measurements, use a real signed app container whose App ID,
provisioning profile, and executable signature all include
`com.apple.developer.private-cloud-compute`. Record network conditions and region
notes with the exported result.

## Apple Evaluations Replay

The portable benchmark package does not depend on Apple's macOS-only Evaluations
framework. The separate `Evaluations` package replays recorded JSON results into
native `.xcevalresult` artifacts without running the measured model again.

```bash
./foundation-models-bench-evaluate replay \
  Results/run.json \
  --output /tmp/foundation-models-bench-evaluations \
  --format json
```

The deterministic replay artifact remains the primary evidence. Optional PCC judge
artifacts are secondary and should be reported separately.

## Valid Result Policy

A publishable result must include:

- JSON report produced by the benchmark.
- Markdown summary or table derived from the same JSON.
- Exact commit SHA.
- Device model and hardware identifier.
- OS version and build.
- Model route: on-device, PCC, or adapter name.
- Warmups, repetitions, sample selection, seed, and session mode.
- Thermal state, Low Power Mode, and timestamp.
- PCC entitlement evidence for PCC runs.
- Disclosure of failures and unavailable scenarios.

Invalid as benchmark evidence:

- Simulator runs.
- Manually edited reports.
- Results without OS build.
- PCC numbers from an unsigned or unentitled process.
- Comparisons that change fixtures, seed, sample selection, warmups, or repetitions
  without saying so.

## Repository Layout

```text
Sources/FoundationModelsBenchCore/        Scenarios, runner, graders, metrics, reports
Sources/FoundationModelsBenchCLI/         SwiftPM command-line runner
Tests/FoundationModelsBenchCoreTests/     Offline validation tests
FoundationModelsBenchDeviceRunner/        Signed iOS/macOS runner for device and PCC runs
Evaluations/                              macOS 27 recorded-result replay package
Results/                                  Curated JSON and Markdown benchmark results
docs/                                     Methodology, PCC notes, device matrix, research notes
```

## Documentation

- [Methodology](docs/METHODOLOGY.md)
- [Research Notes](docs/RESEARCH_NOTES.md)
- [Private Cloud Compute](docs/PCC.md)
- [Device Matrix](docs/DEVICE_MATRIX.md)
- [OS 26 vs OS 27](docs/OS_26_VS_27.md)
- [Apple Evaluations Replay](docs/EVALUATIONS.md)

## Status

Foundation Models Bench is an independent open-source benchmark. It is not an Apple
benchmark and is not endorsed by Apple. The goal is to provide a transparent,
community-reviewable standard for Foundation Models and Private Cloud Compute
measurement.

## Contributing

Contributions should improve reproducibility, coverage, or evidence quality. New
scenarios need synthetic fixtures, deterministic checks, documented provenance, and
tests. See [CONTRIBUTING.md](CONTRIBUTING.md).
