# Contributing

Foundation Models Bench welcomes contributions that improve reproducibility,
coverage, methodology, or reporting clarity.

## What Belongs

- New synthetic scenarios with deterministic checks.
- Better Foundation Models or PCC environment capture.
- Device-runner improvements for signed, publishable measurements.
- Result-schema improvements with tests and documentation.
- Apple Evaluations replay improvements that do not change benchmark execution.

## What Does Not Belong

- Proprietary or user-derived data.
- Simulator output presented as benchmark evidence.
- Single-number aggregate scoring that hides quality, safety, failures, or latency.
- Provider-specific marketing claims.
- Migration aliases for retired public names.

## Scenario Requirements

Every new scenario should include:

- Stable scenario and sample IDs.
- Synthetic fixture data.
- Documented inspiration or provenance.
- Deterministic checks for semantic success.
- Tests for grading behavior.
- Notes for OS, model, tool, visual, network, or entitlement requirements.

## Result Requirements

Curated results should include JSON and Markdown generated from the same run. Include
the commit SHA, device, OS build, model route, warmups, repetitions, seed, session
mode, thermal state, Low Power Mode, and timestamp.

Private Cloud Compute results must also document entitlement evidence and network
conditions.

## Development

```bash
swift test
swift run foundation-models-bench list
```

Use Xcode 27 when validating the `Evaluations` package.
