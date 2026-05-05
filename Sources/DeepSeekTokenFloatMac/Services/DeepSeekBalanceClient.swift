import Foundation

enum DeepSeekBalanceClientError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add a DeepSeek API Key in Settings first."
        case .invalidResponse:
            return "DeepSeek returned an invalid response."
        case .requestFailed(let statusCode):
            if statusCode == 401 || statusCode == 403 {
                return "DeepSeek rejected the API Key. Check the key and try again."
            }
            return "DeepSeek balance request failed with HTTP \(statusCode)."
        case .decodingFailed:
            return "DeepSeek balance response could not be decoded."
        }
    }
}

struct DeepSeekBalanceClient {
    private let endpoint = URL(string: "https://api.deepseek.com/user/balance")

    func fetchBalance(apiKey: String) async throws -> DeepSeekBalanceResponse {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw DeepSeekBalanceClientError.missingAPIKey
        }
        guard let endpoint else {
            throw DeepSeekBalanceClientError.invalidResponse
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekBalanceClientError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw DeepSeekBalanceClientError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
        } catch {
            throw DeepSeekBalanceClientError.decodingFailed
        }
    }
}
