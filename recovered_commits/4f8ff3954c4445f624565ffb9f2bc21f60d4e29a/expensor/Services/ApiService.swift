import Foundation
import Supabase
import SwiftUI

enum HttpMethod: String {
    case GET, POST, PUT, DELETE
}

class ApiService {
    static let shared = ApiService()

    private init() {}

    func request(
        method: HttpMethod,
        urlString: String,
        body: [String: Any]? = nil
    ) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let session = try await supabase.auth.session
        let jwtToken = session.accessToken
        
        print(jwtToken, "tjhe token here")

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("access_token=\(jwtToken)", forHTTPHeaderField: "Cookie")

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
        func uploadReceipt(
            urlString: String,
            fields: [String: String],
            images: [UIImage]
        ) async throws -> Data {
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()

            // Append text fields
            for (name, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }

            // Append images
            for (index, image) in images.enumerated() {
                if let imageData = image.jpegData(compressionQuality: 1) {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"images[]\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                    body.append(imageData)
                    body.append("\r\n".data(using: .utf8)!)
                }
            }
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }

            let session = try await supabase.auth.session
            let jwtToken = session.accessToken

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            request.setValue("access_token=\(jwtToken)", forHTTPHeaderField: "Cookie")
            request.httpBody = body

            let (data, _) = try await URLSession.shared.data(for: request)
            return data
    }
}
