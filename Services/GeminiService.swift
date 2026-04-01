import UIKit
import Foundation

struct GeminiService {

    private let apiKey = Secrets.geminiAPIKey
    private let model = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    // MARK: - Step 1: Extract dominant colors from image
    func extractColors(_ image: UIImage) async throws -> [NailColor] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        You are a color expert. Analyze this image and extract the 4 most dominant colors.

        Return ONLY valid JSON (no markdown, no code blocks) in exactly this format:
        {
          "colors": [
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"}
          ]
        }

        Rules:
        - Return exactly 4 colors sorted by dominance (most dominant first)
        - Give each an elegant, descriptive name (e.g. "Rose Blush", "Forest Sage")
        - Hex codes must NOT include the # symbol
        - Return ONLY the JSON object, nothing else
        """

        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]],
                    ["text": prompt]
                ]
            ]]
        ]

        let data = try await makeRequest(body: requestBody)
        let text = try extractText(from: data)
        let json = try parseJSON(text)

        let colorsArray = json["colors"] as? [[String: String]] ?? []
        let colors = colorsArray.compactMap { dict -> NailColor? in
            guard let name = dict["name"], let hex = dict["hex"] else { return nil }
            return NailColor(name: name, hex: hex)
        }
        guard !colors.isEmpty else { throw GeminiError.parseError }
        return colors
    }

    // MARK: - Step 2: Generate designs based on selected colors (no image needed)
    func generateDesigns(for colors: [NailColor]) async throws -> [DesignSuggestion] {
        let colorList = colors.enumerated().map { i, c in
            "Color \(i + 1): \(c.name) (#\(c.hex))"
        }.joined(separator: "\n")

        let prompt = """
        You are a professional nail art designer. Create 4 nail art design suggestions using these colors:
        \(colorList)

        Return ONLY valid JSON (no markdown, no code blocks) in exactly this format:
        {
          "suggestions": [
            {"emoji": "🎨", "title": "Design Name", "description": "Vivid description of the nail art.", "pattern": "ombre"},
            {"emoji": "✨", "title": "Design Name", "description": "Vivid description of the nail art.", "pattern": "french"},
            {"emoji": "🌸", "title": "Design Name", "description": "Vivid description of the nail art.", "pattern": "solid"},
            {"emoji": "💎", "title": "Design Name", "description": "Vivid description of the nail art.", "pattern": "glitter"}
          ]
        }

        Rules:
        - Suggest exactly 4 designs
        - Each design should use 1 or 2 of the provided colors — not all mixed together
        - Descriptions must be specific to the actual colors given
        - pattern must be one of: solid, ombre, french, glitter, abstract
        - Return ONLY the JSON object, nothing else
        """

        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]]
        ]

        let data = try await makeRequest(body: requestBody)
        let text = try extractText(from: data)
        let json = try parseJSON(text)

        let suggestionsArray = json["suggestions"] as? [[String: String]] ?? []
        let suggestions = suggestionsArray.compactMap { dict -> DesignSuggestion? in
            guard let emoji = dict["emoji"],
                  let title = dict["title"],
                  let description = dict["description"] else { return nil }
            let pattern = NailPattern(rawValue: dict["pattern"] ?? "") ?? .solid
            return DesignSuggestion(emoji: emoji, title: title, description: description, pattern: pattern)
        }
        guard !suggestions.isEmpty else { throw GeminiError.parseError }
        return suggestions
    }

    // MARK: - Shared Helpers
    private func makeRequest(body: [String: Any]) async throws -> Data {
        let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw GeminiError.apiError }
        if http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("Gemini API error \(http.statusCode): \(body)")
            throw GeminiError.apiError
        }
        return data
    }

    private func extractText(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.parseError
        }
        return text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseJSON(_ text: String) throws -> [String: Any] {
        guard let jsonData = text.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.parseError
        }
        return result
    }
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case imageEncodingFailed
    case apiError
    case parseError

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed: return "Failed to process the image."
        case .apiError:            return "Could not reach the AI service. Please check your connection and try again."
        case .parseError:          return "Could not read the AI response. Please try again."
        }
    }
}
