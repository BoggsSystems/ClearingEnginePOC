import Foundation

class TradeViewModel: ObservableObject {
    // Input Fields
    @Published var buyer: String = "" { didSet { validateForm() } }
    @Published var seller: String = "" { didSet { validateForm() } }
    @Published var instrument: String = "" { didSet { validateForm() } }
    @Published var quantity: String = "" { didSet { validateForm() } }
    @Published var price: String = "" { didSet { validateForm() } }
    @Published var trades: [Trade] = []

    // Output Fields
    @Published var statusMessage: String = ""
    @Published var tradeResponse: TradeResponse? = nil

    // Loading State
    @Published var isLoading: Bool = false

    // Validation Flags
    @Published var isFormValid: Bool = false
    @Published var errorMessages: [String] = []

    private let tradeService = TradeService()

    // MARK: - Public Methods
    func submitTrade() {
        // Clear previous status
        statusMessage = ""
        tradeResponse = nil

        // Validate inputs
        guard validateForm() else {
            statusMessage = "Please correct the errors before submitting."
            return
        }

        // Convert inputs to appropriate types
        guard let quantityInt = Int(quantity), let priceDouble = Double(price) else {
            statusMessage = "Invalid quantity or price. Please enter valid numbers."
            return
        }

        // Create trade object
        let trade = Trade(
            id: UUID().uuidString,
            buyer: buyer,
            seller: seller,
            instrument: instrument,
            quantity: quantityInt,
            price: priceDouble
        )

        isLoading = true // Start loading
        tradeService.submitTrade(trade) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false // Stop loading
                switch result {
                case .success(let tradeResponse):
                    self?.tradeResponse = tradeResponse
                    self?.statusMessage = "Trade submitted successfully!"
                case .failure(let error):
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Private Methods
    private func validateForm() -> Bool {
        errorMessages = []

        if buyer.isEmpty {
            errorMessages.append("Buyer field is required.")
        }

        if seller.isEmpty {
            errorMessages.append("Seller field is required.")
        }

        if instrument.isEmpty {
            errorMessages.append("Instrument field is required.")
        }

        if quantity.isEmpty || Int(quantity) == nil {
            errorMessages.append("Quantity must be a valid number.")
        }

        if price.isEmpty || Double(price) == nil {
            errorMessages.append("Price must be a valid number.")
        }

        isFormValid = errorMessages.isEmpty
        return isFormValid
    }
}

// MARK: - Models

// Trade Model - Represents the trade data being sent to the API
struct Trade: Codable, Identifiable {
    let id: String
    let buyer: String
    let seller: String
    let instrument: String
    let quantity: Int
    let price: Double
}

struct TradeResponse: Codable {
    let trade: Trade
    let matchedTrade: Trade?
    let nettingResult: NettingResult?
    let settlementInstruction: String?
}

struct NettingResult: Codable {
    let tradeId: String
    let counterparty: String
    let netPosition: Int
}


enum MatchedTrade: Codable {
    case trade(Trade)
    case message(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let trade = try? container.decode(Trade.self) {
            self = .trade(trade)
        } else if let message = try? container.decode(String.self) {
            self = .message(message)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "MatchedTrade could not be decoded.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .trade(let trade):
            try container.encode(trade)
        case .message(let message):
            try container.encode(message)
        }
    }
}



// API Error Model - For detailed error handling
struct APIError: Codable, Error {
    let message: String
}

