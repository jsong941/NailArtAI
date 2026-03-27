import UIKit
import Foundation

struct GeminiService {

    // MARK: - Configuration
    // Paste your Gemini API key here (get one free at aistudio.google.com)
    private let apiKey = Secrets.geminiAPIKey
    private let model = "gemini-2.5-flash"

    // MARK: - Analyze Image
    func analyzeImage(_ image: UIImage) async throws -> AnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        You are a professional nail art designer. Analyze this image and suggest nail art designs inspired by its colors and aesthetic.

        Return ONLY valid JSON (no markdown, no code blocks, no explanation) in exactly this format:
        {
          "colors": [
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"},
            {"name": "Color Name", "hex": "RRGGBB"}
          ],
          "suggestions": [
            {"emoji": "🎨", "title": "Design Name", "description": "A short description of the nail art design."},
            {"emoji": "✨", "title": "Design Name", "description": "A short description of the nail art design."},
            {"emoji": "🌸", "title": "Design Name", "description": "A short description of the nail art design."},
            {"emoji": "💅", "title": "Design Name", "description": "A short description of the nail art design."}
          ]
        }

        Rules:
        - Extract exactly 5 colors from the image
        - Suggest exactly 4 nail art designs
        - Hex codes must NOT include the # symbol
        - Return ONLY the JSON object, nothing else
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError
        }

        if httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("Gemini API error \(httpResponse.statusCode): \(body)")
            throw GeminiError.apiError
        }

        return try parseResponse(data)
    }

    // MARK: - Parse Response
    private func parseResponse(_ data: Data) throws -> AnalysisResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.parseError
        }

        // Strip any markdown code fences Gemini might add despite instructions
        let cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanText.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw GeminiError.parseError
        }

        let colorsArray = result["colors"] as? [[String: String]] ?? []
        let colors = colorsArray.compactMap { dict -> NailColor? in
            guard let name = dict["name"], let hex = dict["hex"] else { return nil }
            return NailColor(name: name, hex: hex)
        }

        let suggestionsArray = result["suggestions"] as? [[String: String]] ?? []
        let suggestions = suggestionsArray.compactMap { dict -> DesignSuggestion? in
            guard let emoji = dict["emoji"],
                  let title = dict["title"],
                  let description = dict["description"] else { return nil }
            return DesignSuggestion(emoji: emoji, title: title, description: description)
        }

        guard !colors.isEmpty, !suggestions.isEmpty else {
            throw GeminiError.parseError
        }

        return AnalysisResult(colors: colors, suggestions: suggestions)
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
        case .apiError: return "Could not reach the AI service. Please check your connection and try again."
        case .parseError: return "Could not read the AI response. Please try again."
        }
    }
}
