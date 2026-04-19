import Foundation

struct OpenAIClient {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")

    func translate(text: String, sourceLanguage: String, targetLanguages: [String], token: String, context: String, model: String) async throws -> [String: String] {
        guard let endpoint else {
            throw OpenAIError.invalidEndpoint
        }

        let trimmedTargets = targetLanguages.filter { !$0.isEmpty }
        guard !trimmedTargets.isEmpty else {
            return [:]
        }

        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextBlock = trimmedContext.isEmpty ? "" : "Context:\n\(trimmedContext)\n\n"

        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedModel = trimmedModel.isEmpty ? "gpt-4.1" : trimmedModel

        let prompt = """
        Translate the text from \(sourceLanguage) into the following target languages: \(trimmedTargets.joined(separator: ", ")).
        Preserve placeholders, punctuation, and line breaks. Return only JSON.

        \(contextBlock)Text:
        \(text)
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "translations": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "language": ["type": "string"],
                            "text": ["type": "string"]
                        ],
                        "required": ["language", "text"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "required": ["translations"],
            "additionalProperties": false
        ]

        let requestBody: [String: Any] = [
            "model": resolvedModel,
            "input": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "translations",
                    "schema": schema,
                    "strict": true
                ]
            ],
            "temperature": 0.2
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let outputText = decoded.outputText else {
            throw OpenAIError.missingOutput
        }

        let translationResponse = try JSONDecoder().decode(OpenAITranslationResponse.self, from: Data(outputText.utf8))
        var results: [String: String] = [:]
        for item in translationResponse.translations {
            results[item.language] = item.text
        }
        return results
    }
}

private struct OpenAIResponse: Decodable {
    let output: [OpenAIOutputItem]

    var outputText: String? {
        output
            .flatMap { $0.content ?? [] }
            .first { $0.type == "output_text" }?
            .text
    }
}

private struct OpenAIOutputItem: Decodable {
    let content: [OpenAIOutputContent]?
}

private struct OpenAIOutputContent: Decodable {
    let type: String
    let text: String?
}

private struct OpenAITranslationResponse: Decodable {
    let translations: [OpenAITranslationItem]
}

private struct OpenAITranslationItem: Decodable {
    let language: String
    let text: String
}

enum OpenAIError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case missingOutput

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The OpenAI endpoint could not be created."
        case .invalidResponse:
            return "The OpenAI response was invalid."
        case .requestFailed(let statusCode, let message):
            return "OpenAI request failed (\(statusCode)): \(message)"
        case .missingOutput:
            return "OpenAI response did not include translated text."
        }
    }
}
