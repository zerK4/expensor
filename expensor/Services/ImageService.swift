//
//  ImageService.swift
//  expensor
//
//  Created by Sebastian Pavel on 28.05.2025.
//

import Foundation
import UIKit
@preconcurrency import Vision
import CoreImage

final class ImageService {
    static let shared = ImageService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Extracts text from an image and returns JSON string
    func extractTextFromImage(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw TextExtractionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: TextExtractionError.noTextFound)
                    return
                }
                
                let textResults = observations.compactMap { observation -> TextResult? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    let boundingBox = observation.boundingBox
                    return TextResult(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: BoundingBox(
                            x: boundingBox.origin.x,
                            y: boundingBox.origin.y,
                            width: boundingBox.size.width,
                            height: boundingBox.size.height
                        )
                    )
                }
                
                let result = ExtractionResult(
                    success: true,
                    textResults: textResults,
                    fullText: textResults.map { $0.text }.joined(separator: "\n"),
                    timestamp: ISO8601DateFormatter().string(from: Date())
                )
                
                do {
                    let jsonData = try JSONEncoder().encode(result)
                    let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                    continuation.resume(returning: jsonString)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Configure recognition options
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Assesses image quality to determine if Vision OCR or AI should be used
    func assessImageQuality(_ image: UIImage) async -> ImageQualityResult {
        let assessments = await withTaskGroup(of: QualityMetric.self, returning: [QualityMetric].self) { group in
            var metrics: [QualityMetric] = []
            
            // Check resolution
            group.addTask {
                return self.checkResolution(image)
            }
            
            // Check sharpness/blur
            group.addTask {
                return await self.checkSharpness(image)
            }
            
            // Check brightness/contrast
            group.addTask {
                return self.checkBrightnessContrast(image)
            }
            
            // Check if image is too small for text
            group.addTask {
                return self.checkTextReadability(image)
            }
            
            for await metric in group {
                metrics.append(metric)
            }
            
            return metrics
        }
        
        let overallScore = calculateOverallScore(assessments)
        let recommendation = determineRecommendation(overallScore, assessments)
        
        return ImageQualityResult(
            overallScore: overallScore,
            recommendation: recommendation,
            metrics: assessments,
            shouldUseAI: overallScore < 0.6, // If quality is below 60%, recommend AI
            issues: identifyIssues(assessments)
        )
    }
    
    /// Convenience method that combines quality assessment and text extraction
    func smartTextExtraction(_ image: UIImage) async throws -> SmartExtractionResult {
        let qualityResult = await assessImageQuality(image)
        
        let extractionResult: String
        let method: ExtractionMethod
        
        if qualityResult.shouldUseAI {
            // For now, we'll still use Vision but mark it as needing AI
            // You can implement AI service call here later
            extractionResult = try await extractTextFromImage(image)
            method = .aiRecommended
        } else {
            extractionResult = try await extractTextFromImage(image)
            method = .vision
        }
        
        return SmartExtractionResult(
            extractionResult: extractionResult,
            qualityAssessment: qualityResult,
            methodUsed: method
        )
    }
}

// MARK: - Private Quality Assessment Methods

private extension ImageService {
    
    func checkResolution(_ image: UIImage) -> QualityMetric {
        let totalPixels = image.size.width * image.size.height * image.scale * image.scale
        let megapixels = totalPixels / 1_000_000
        
        var score: Double
        var status: QualityStatus
        
        if megapixels >= 2.0 {
            score = 1.0
            status = .excellent
        } else if megapixels >= 1.0 {
            score = 0.8
            status = .good
        } else if megapixels >= 0.5 {
            score = 0.6
            status = .acceptable
        } else {
            score = 0.3
            status = .poor
        }
        
        return QualityMetric(
            name: "Resolution",
            score: score,
            status: status,
            details: "\(String(format: "%.1f", megapixels))MP (\(Int(image.size.width * image.scale))x\(Int(image.size.height * image.scale)))",
            weight: 0.25
        )
    }
    
    func checkSharpness(_ image: UIImage) async -> QualityMetric {
        guard let cgImage = image.cgImage else {
            return QualityMetric(name: "Sharpness", score: 0.0, status: .poor, details: "Cannot analyze", weight: 0.3)
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // Apply Laplacian filter to detect edges (sharpness indicator)
        let laplacianKernel = CIFilter(name: "CIConvolution3X3")!
        laplacianKernel.setValue(ciImage, forKey: kCIInputImageKey)
        laplacianKernel.setValue(CIVector(values: [0, -1, 0, -1, 4, -1, 0, -1, 0], count: 9), forKey: "inputWeights")
        
        guard let outputImage = laplacianKernel.outputImage,
              let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) else {
            return QualityMetric(name: "Sharpness", score: 0.5, status: .acceptable, details: "Analysis failed", weight: 0.3)
        }
        
        // Calculate variance of the filtered image (higher variance = sharper)
        let variance = calculateImageVariance(cgOutput)
        
        var score: Double
        var status: QualityStatus
        
        if variance > 1000 {
            score = 1.0
            status = .excellent
        } else if variance > 500 {
            score = 0.8
            status = .good
        } else if variance > 200 {
            score = 0.6
            status = .acceptable
        } else {
            score = 0.3
            status = .poor
        }
        
        return QualityMetric(
            name: "Sharpness",
            score: score,
            status: status,
            details: "Variance: \(Int(variance))",
            weight: 0.3
        )
    }
    
    func checkBrightnessContrast(_ image: UIImage) -> QualityMetric {
        guard let cgImage = image.cgImage else {
            return QualityMetric(name: "Brightness/Contrast", score: 0.0, status: .poor, details: "Cannot analyze", weight: 0.25)
        }
        
        let brightness = calculateAverageBrightness(cgImage)
        
        var score: Double
        var status: QualityStatus
        var details: String
        
        // Optimal brightness is around 0.3-0.7 (30%-70%)
        if brightness >= 0.3 && brightness <= 0.7 {
            score = 1.0
            status = .excellent
            details = "Optimal brightness (\(Int(brightness * 100))%)"
        } else if brightness >= 0.2 && brightness <= 0.8 {
            score = 0.7
            status = .good
            details = "Good brightness (\(Int(brightness * 100))%)"
        } else if brightness >= 0.1 && brightness <= 0.9 {
            score = 0.5
            status = .acceptable
            details = "Acceptable brightness (\(Int(brightness * 100))%)"
        } else {
            score = 0.2
            status = .poor
            if brightness < 0.1 {
                details = "Too dark (\(Int(brightness * 100))%)"
            } else {
                details = "Too bright (\(Int(brightness * 100))%)"
            }
        }
        
        return QualityMetric(
            name: "Brightness/Contrast",
            score: score,
            status: status,
            details: details,
            weight: 0.25
        )
    }
    
    func checkTextReadability(_ image: UIImage) -> QualityMetric {
        let imageArea = image.size.width * image.size.height * image.scale * image.scale
        let aspectRatio = max(image.size.width, image.size.height) / min(image.size.width, image.size.height)
        
        var score: Double = 1.0
        var issues: [String] = []
        
        // Very small images are hard to read
        if imageArea < 300_000 { // Less than 0.3MP
            score -= 0.4
            issues.append("Very small image")
        }
        
        // Extremely wide or tall images might have small text
        if aspectRatio > 3.0 {
            score -= 0.2
            issues.append("Unusual aspect ratio")
        }
        
        let status: QualityStatus
        if score >= 0.8 {
            status = .excellent
        } else if score >= 0.6 {
            status = .good
        } else if score >= 0.4 {
            status = .acceptable
        } else {
            status = .poor
        }
        
        return QualityMetric(
            name: "Text Readability",
            score: max(0.0, score),
            status: status,
            details: issues.isEmpty ? "Good for text recognition" : issues.joined(separator: ", "),
            weight: 0.2
        )
    }
    
    // MARK: - Helper Functions
    
    func calculateImageVariance(_ cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let data = CFDataCreateMutable(nil, width * height * bytesPerPixel),
              let context = CGContext(data: CFDataGetMutableBytePtr(data),
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return 0.0
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let pixelData = CFDataGetBytePtr(data)!
        var sum: Double = 0
        var sumSquares: Double = 0
        let totalPixels = width * height
        
        for i in stride(from: 0, to: totalPixels * bytesPerPixel, by: bytesPerPixel) {
            // Convert to grayscale
            let gray = 0.299 * Double(pixelData[i]) + 0.587 * Double(pixelData[i + 1]) + 0.114 * Double(pixelData[i + 2])
            sum += gray
            sumSquares += gray * gray
        }
        
        let mean = sum / Double(totalPixels)
        let variance = (sumSquares / Double(totalPixels)) - (mean * mean)
        
        return variance
    }
    
    func calculateAverageBrightness(_ cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let data = CFDataCreateMutable(nil, width * height * bytesPerPixel),
              let context = CGContext(data: CFDataGetMutableBytePtr(data),
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return 0.5
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let pixelData = CFDataGetBytePtr(data)!
        var totalBrightness: Double = 0
        let totalPixels = width * height
        
        for i in stride(from: 0, to: totalPixels * bytesPerPixel, by: bytesPerPixel) {
            let brightness = (Double(pixelData[i]) + Double(pixelData[i + 1]) + Double(pixelData[i + 2])) / (3.0 * 255.0)
            totalBrightness += brightness
        }
        
        return totalBrightness / Double(totalPixels)
    }
    
    func calculateOverallScore(_ metrics: [QualityMetric]) -> Double {
        let weightedSum = metrics.reduce(0.0) { sum, metric in
            sum + (metric.score * metric.weight)
        }
        let totalWeight = metrics.reduce(0.0) { sum, metric in
            sum + metric.weight
        }
        return totalWeight > 0 ? weightedSum / totalWeight : 0.0
    }
    
    func determineRecommendation(_ score: Double, _ metrics: [QualityMetric]) -> String {
        if score >= 0.8 {
            return "Image quality is excellent for Vision framework OCR"
        } else if score >= 0.6 {
            return "Image quality is good for Vision framework OCR"
        } else if score >= 0.4 {
            return "Image quality is marginal - consider using AI for better results"
        } else {
            return "Image quality is poor - strongly recommend using AI for text extraction"
        }
    }
    
    func identifyIssues(_ metrics: [QualityMetric]) -> [String] {
        return metrics.compactMap { metric in
            if metric.status == .poor {
                return "Poor \(metric.name.lowercased())"
            }
            return nil
        }
    }
}

// MARK: - Data Models

struct ExtractionResult: Codable {
    let success: Bool
    let textResults: [TextResult]
    let fullText: String
    let timestamp: String
}

struct TextResult: Codable {
    let text: String
    let confidence: Float
    let boundingBox: BoundingBox
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct ImageQualityResult {
    let overallScore: Double
    let recommendation: String
    let metrics: [QualityMetric]
    let shouldUseAI: Bool
    let issues: [String]
}

struct QualityMetric {
    let name: String
    let score: Double
    let status: QualityStatus
    let details: String
    let weight: Double
}

struct SmartExtractionResult {
    let extractionResult: String
    let qualityAssessment: ImageQualityResult
    let methodUsed: ExtractionMethod
}

enum QualityStatus {
    case excellent, good, acceptable, poor
    
    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .acceptable: return "Acceptable"
        case .poor: return "Poor"
        }
    }
}

enum ExtractionMethod {
    case vision
    case aiRecommended
    
    var description: String {
        switch self {
        case .vision: return "Vision Framework"
        case .aiRecommended: return "AI Recommended"
        }
    }
}

// MARK: - Error Types

enum TextExtractionError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .noTextFound:
            return "No text found in image"
        }
    }
}
