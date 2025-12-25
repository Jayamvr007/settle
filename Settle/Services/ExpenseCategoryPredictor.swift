//
//  ExpenseCategoryPredictor.swift
//  Settle
//
//  Core ML text classifier for auto-categorizing expenses.
//

import Foundation
import NaturalLanguage

class ExpenseCategoryPredictor {
    static let shared = ExpenseCategoryPredictor()
    
    private var classifier: NLModel?
    private var isModelLoaded = false
    
    // Fallback keyword-based classification when model isn't available
    private let categoryKeywords: [ExpenseCategory: [String]] = [
        .food: ["pizza", "dinner", "lunch", "breakfast", "coffee", "restaurant", "swiggy", "zomato", 
                "food", "meal", "snack", "biryani", "burger", "kfc", "mcdonalds", "dominos", 
                "starbucks", "tea", "chai", "cafe", "takeaway", "delivery"],
        .groceries: ["vegetables", "fruits", "grocery", "supermarket", "bigbasket", "zepto", 
                     "blinkit", "instamart", "dmart", "reliance fresh", "spencers", "milk", "eggs", "rice"],
        .transport: ["uber", "ola", "cab", "taxi", "metro", "bus fare", "auto", "rapido", 
                     "petrol", "diesel", "fuel", "parking", "toll", "cng", "rickshaw"],
        .travel: ["flight", "train ticket", "irctc", "makemytrip", "goibibo", "hotel", "oyo", 
                  "airbnb", "indigo", "vistara", "spicejet", "redbus", "yatra", "vacation", "holiday"],
        .entertainment: ["movie", "cinema", "pvr", "inox", "concert", "gaming", "bowling", 
                         "amusement", "zoo", "museum", "pub", "bar", "club", "party", "event"],
        .subscriptions: ["netflix", "amazon prime", "hotstar", "spotify", "youtube premium", 
                         "apple music", "zee5", "sonyliv", "gym membership", "subscription"],
        .utilities: ["electricity", "water bill", "wifi", "internet", "broadband", "mobile recharge", 
                     "phone bill", "rent", "maintenance", "jio", "airtel", "vi", "bsnl", "gas bill"],
        .shopping: ["amazon", "flipkart", "myntra", "ajio", "clothes", "shoes", "electronics", 
                    "phone", "laptop", "furniture", "gift", "watch", "ball", "bat", "racket", "sports gear"],
        .healthcare: ["doctor", "hospital", "clinic", "medicine", "pharmacy", "apollo", "fortis", 
                      "medplus", "pharmeasy", "1mg", "netmeds", "lab test", "dental", "health checkup"],
        .education: ["tuition", "school fees", "college", "course", "udemy", "coursera", "upgrad", 
                     "byju", "unacademy", "books", "stationery", "coaching", "exam fees"]
    ]
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        // Try to load the Core ML model
        guard let modelURL = Bundle.main.url(forResource: "ExpenseClassifier", 
                                              withExtension: "mlmodelc") else {
            print("⚠️ ExpenseClassifier model not found, using keyword fallback")
            return
        }
        
        do {
            classifier = try NLModel(contentsOf: modelURL)
            isModelLoaded = true
            print("✅ ExpenseClassifier model loaded successfully")
        } catch {
            print("❌ Failed to load ExpenseClassifier: \(error)")
        }
    }
    
    /// Predict category from expense description
    func predict(description: String) -> ExpenseCategory {
        let cleanedText = description.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedText.isEmpty else { return .general }
        
        // Use Core ML model if available
        if isModelLoaded, let classifier = classifier {
            if let prediction = classifier.predictedLabel(for: cleanedText),
               let category = ExpenseCategory(rawValue: prediction) {
                return category
            }
        }
        
        // Fallback to keyword matching
        return predictUsingKeywords(cleanedText)
    }
    
    /// Get confidence scores for all categories (requires Core ML model)
    func predictWithConfidence(description: String) -> [(category: ExpenseCategory, confidence: Double)] {
        let cleanedText = description.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedText.isEmpty else { return [] }
        
        if isModelLoaded, let classifier = classifier {
            let hypotheses = classifier.predictedLabelHypotheses(for: cleanedText, maximumCount: 6)
            return hypotheses.compactMap { (label, confidence) in
                guard let category = ExpenseCategory(rawValue: label) else { return nil }
                return (category, confidence)
            }.sorted { $0.confidence > $1.confidence }
        }
        
        // Fallback: return single prediction with 1.0 confidence
        let predicted = predictUsingKeywords(cleanedText)
        return [(predicted, 1.0)]
    }
    
    /// Keyword-based fallback classifier with confidence
    private func predictUsingKeywords(_ text: String) -> ExpenseCategory {
        var bestMatch: ExpenseCategory = .general
        var highestScore = 0
        
        for (category, keywords) in categoryKeywords {
            let matchCount = keywords.filter { text.contains($0) }.count
            if matchCount > highestScore {
                highestScore = matchCount
                bestMatch = category
            }
        }
        
        // Only return non-general if we have at least one keyword match
        return highestScore > 0 ? bestMatch : .general
    }
    
    /// Keyword fallback with confidence scores
    func predictWithConfidenceUsingKeywords(_ text: String) -> [(category: ExpenseCategory, confidence: Double)] {
        var scores: [ExpenseCategory: Int] = [:]
        
        for (category, keywords) in categoryKeywords {
            scores[category] = keywords.filter { text.contains($0) }.count
        }
        
        let maxScore = scores.values.max() ?? 0
        if maxScore == 0 {
            return [(.general, 0.3)] // Low confidence for general
        }
        
        return scores.compactMap { (category, score) in
            guard score > 0 else { return nil }
            let confidence = Double(score) / Double(maxScore)
            return (category, confidence)
        }.sorted { $0.confidence > $1.confidence }
    }
    
    /// Check if Core ML model is loaded
    var isUsingCoreML: Bool {
        return isModelLoaded
    }
}
