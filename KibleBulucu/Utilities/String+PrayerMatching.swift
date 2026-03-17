import Foundation

extension String {
    var prayerMatchingKey: String {
        let lowered = self
            .replacingOccurrences(of: "İ", with: "I")
            .replacingOccurrences(of: "I", with: "i")
            .replacingOccurrences(of: "ı", with: "i")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()

        let filtered = lowered.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
}
