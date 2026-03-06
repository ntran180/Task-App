import Foundation

enum SuggestServiceError: Error {
    case invalidURL
    case badStatus(Int)
}

/// Example of explicit HTTP/JSON communication (e.g. Cloud Function).
final class SuggestService {
    static let shared = SuggestService()
    private init() {}

    struct SuggestResponse: Codable {
        let taskId: String
        let title: String
        let description: String?
        let durationMinutes: Int
        let categoryId: String?
    }

    func suggestTask(uid: String, durationMinutes: Int) async throws -> SuggestResponse {
        // Replace with your deployed endpoint.
        // Example: https://<region>-<project>.cloudfunctions.net/suggest?uid=...&duration=5
        var components = URLComponents(string: "https://example.com/suggest")
        components?.queryItems = [
            URLQueryItem(name: "uid", value: uid),
            URLQueryItem(name: "duration", value: "\(durationMinutes)")
        ]
        guard let url = components?.url else { throw SuggestServiceError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw SuggestServiceError.badStatus(http.statusCode)
        }
        return try JSONDecoder().decode(SuggestResponse.self, from: data)
    }
}

