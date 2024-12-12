import SwiftUI

struct TradeEntryView: View {
    @StateObject private var viewModel = TradeViewModel()
    @State private var selectedTab = "Submit"

    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedTab) {
                    Text("Submit Trade").tag("Submit")
                    Text("View Results").tag("Results")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Add animation for tab transition
                if selectedTab == "Submit" {
                    withAnimation {
                        submitTradeView
                    }
                } else {
                    withAnimation {
                        resultsView
                    }
                }
            }
            .padding()
            .navigationTitle("Clearing Engine")
            .overlay(
                viewModel.isLoading ? loadingOverlay : nil
            )
        }
    }

    private var submitTradeView: some View {
        VStack(spacing: 20) {
            Text("Enter Trade Details")
                .font(.headline)

            Group {
                TextField("Buyer", text: $viewModel.buyer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Seller", text: $viewModel.seller)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Instrument", text: $viewModel.instrument)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Quantity", text: $viewModel.quantity)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Price", text: $viewModel.price)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Button(action: {
                viewModel.submitTrade()
            }) {
                Text("Submit Trade")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.isFormValid)

            // Display Response
            if let response = viewModel.tradeResponse {
                responseView(response: response)
            } else if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .foregroundColor(viewModel.statusMessage.contains("Error") ? .red : .blue)
            }
        }
        .padding()
    }

    private var resultsView: some View {
        List {
            Section(header: Text("Submitted Trades")) {
                ForEach(viewModel.trades, id: \.id) { trade in
                    VStack(alignment: .leading) {
                        Text("Buyer: \(trade.buyer) | Seller: \(trade.seller)")
                        Text("Instrument: \(trade.instrument)")
                        Text("Quantity: \(trade.quantity) | Price: $\(trade.price, specifier: "%.2f")")
                    }
                }
            }

            Section(header: Text("Settlement Instructions")) {
                if let settlementInstructions = viewModel.tradeResponse?.settlementInstruction {
                    ForEach(settlementInstructions.components(separatedBy: "\n"), id: \.self) { instruction in
                        Text(instruction)
                    }
                } else {
                    Text("No settlement instructions available.")
                        .foregroundColor(.gray)
                }
            }

        }
    }


    private func responseView(response: TradeResponse) -> some View {
        VStack(spacing: 10) {
            Text("Trade Submitted!")
                .font(.headline)
                .foregroundColor(.green)

            Text("Trade ID: \(response.trade.id)")

            if let matchedTrade = response.matchedTrade {
                Text("Matched Trade ID: \(matchedTrade.id)")
                Text("Buyer: \(matchedTrade.buyer)")
                Text("Seller: \(matchedTrade.seller)")
            } else {
                Text("No matching trade found.")
            }

            if let nettingResult = response.nettingResult {
                Text("Netting Result:")
                    .font(.headline)
                Text("Trade ID: \(nettingResult.tradeId)")
                Text("Counterparty: \(nettingResult.counterparty)")
                Text("Net Position: \(nettingResult.netPosition)")
            } else {
                Text("No netting performed.")
            }

            if let settlementInstruction = response.settlementInstruction {
                Text("Settlement Instruction:")
                    .font(.headline)
                Text(settlementInstruction)
                    .multilineTextAlignment(.center)
            } else {
                Text("No settlement instruction generated.")
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(10)
        .shadow(radius: 5)
    }





    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            ProgressView("Submitting Trade...")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}

