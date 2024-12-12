import Foundation

class TradeService {
    private let azureFunctionURL = "https://cdexchangefunctionapp.azurewebsites.net/api/TradeProcessingFunction?code=5UXOiC4WzcAty91GoMYYl1cy95OEg5kpvJgwGsZcbOMhAzFupFwhfw%3D%3D"

    func submitTrade(_ trade: Trade, completion: @escaping (Result<TradeResponse, Error>) -> Void) {
        // Ensure the Azure Function URL is valid
        guard let url = URL(string: azureFunctionURL) else {
            print("Error: Invalid Azure Function URL")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Azure Function URL"])))
            return
        }

        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode the trade object to JSON
        do {
            let requestBody = try JSONEncoder().encode(trade)
            request.httpBody = requestBody
            if let jsonString = String(data: requestBody, encoding: .utf8) {
                print("Request Body: \(jsonString)")
            }
        } catch {
            print("Error encoding request body: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Log HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response: \(httpResponse.statusCode)")
            }

            // Handle HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error: Invalid server response")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])))
                return
            }

            // Log response data
            guard let data = data else {
                print("Error: No data received from server")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from server"])))
                return
            }

            do {
                let tradeResponse = try JSONDecoder().decode(TradeResponse.self, from: data)
                print("Decoded Response: \(tradeResponse)")
                completion(.success(tradeResponse))
            } catch let decodingError {
                // Log additional debugging information
                if let json = String(data: data, encoding: .utf8) {
                    print("Error decoding response. Raw JSON: \(json)")
                }
                print("Decoding Error: \(decodingError.localizedDescription)")
                completion(.failure(decodingError))
            }
        }

        task.resume()
    }
}

