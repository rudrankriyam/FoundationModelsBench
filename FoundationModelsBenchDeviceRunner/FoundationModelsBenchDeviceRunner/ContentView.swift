import FoundationModelsBenchCore
import SwiftUI

struct ContentView: View {
    @State private var viewModel = FoundationModelsBenchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section("Benchmark") {
                    FoundationModelsBenchConfigurationView(viewModel: viewModel)
                }

                Section {
                    FoundationModelsBenchScenarioListView(scenarios: viewModel.selectedScenarios)
                }

                if let result = viewModel.result {
                    Section {
                        FoundationModelsBenchResultView(result: result, copyAction: viewModel.copyMarkdown)
                    }
                }
            }
            .navigationTitle("FoundationModelsBench")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("FoundationModelsBench Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
