import Foundation
import UIKit

enum ApiError: Error {
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case noData
    case decodingError
    case unknown(Error)
}

final class Api {
    static let shared = Api()
    private init() {}

    private func getAccessToken() async -> String? {
        do {
            let token = try await SupabaseManager.shared.auth.session.accessToken
            return token
        } catch {
            print("Error retrieving access token: \(error)")
            return nil
        }
    }

    private func makeRequest(
        url: URL,
        method: String,
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = await getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw ApiError.httpError(statusCode: httpResponse.statusCode, message: message)
            }
            return data
        } catch let error as ApiError {
            throw error
        } catch {
            throw ApiError.unknown(error)
        }
    }

    func get(url: URL) async throws -> Data {
        try await makeRequest(url: url, method: "GET")
    }

    func post<T: Encodable>(url: URL, body: T) async throws -> Data {
        let bodyData = try JSONEncoder().encode(body)
        return try await makeRequest(url: url, method: "POST", body: bodyData)
    }

    func put<T: Encodable>(url: URL, body: T) async throws -> Data {
        let bodyData = try JSONEncoder().encode(body)
        return try await makeRequest(url: url, method: "PUT", body: bodyData)
    }

    func delete(url: URL) async throws -> Data {
        try await makeRequest(url: url, method: "DELETE")
    }

    func postJSON<T: Encodable>(url: URL, body: T) async throws -> Data {
        let bodyData = try JSONEncoder().encode(body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = await getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = bodyData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw ApiError.httpError(statusCode: httpResponse.statusCode, message: message)
            }
            return data
        } catch let error as ApiError {
            throw error
        } catch {
            throw ApiError.unknown(error)
        }
    }
    
    func uploadImages(url: URL, images: [UIImage], fieldName: String = "images[]") async throws -> Data {
            let boundary = UUID().uuidString
            var body = Data()
            for (index, image) in images.enumerated() {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"image\(index).jpg\"\r\n")
                body.append("Content-Type: image/jpeg\r\n\r\n")
                body.append(imageData)
                body.append("\r\n")
            }
            body.append("--\(boundary)--\r\n")
            
            var request = URLRequest(url: url)
        
            if let token = await getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            if let token = await getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = body
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw ApiError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1, message: message)
            }
            return data
        }
    }


private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
