//
//  OCRManager.swift
//  VyroShort
//
//  Apple Vision text recognition + lightweight data detection
//  (URLs / emails / phone numbers).
//

import AppKit
import Vision

struct OCRResult: Sendable {
    var text: String
    var urls: [String]
    var emails: [String]
    var phoneNumbers: [String]

    var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

enum OCRManager {
    /// Recognizes text in the supplied image. Target latency < 1s for typical screenshots.
    static func recognize(in image: NSImage) async -> OCRResult {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return OCRResult(text: "", urls: [], emails: [], phoneNumbers: [])
        }

        let text: String = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            do { try handler.perform([request]) }
            catch { continuation.resume(returning: "") }
        }

        return OCRResult(
            text: text,
            urls: detect(.link, in: text) { $0.url?.absoluteString },
            emails: detectEmails(in: text),
            phoneNumbers: detect(.phoneNumber, in: text) { $0.phoneNumber }
        )
    }

    // MARK: - Detectors

    private static func detect(_ type: NSTextCheckingResult.CheckingType,
                               in text: String,
                               extract: (NSTextCheckingResult) -> String?) -> [String] {
        guard let detector = try? NSDataDetector(types: type.rawValue) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).compactMap(extract)
    }

    private static func detectEmails(in text: String) -> [String] {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
}
