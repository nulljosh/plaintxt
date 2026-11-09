// Settings are a text file, like Sublime. Plain opens it on an empty launch (Mac) and applies it
// whenever it is saved. Keys mirror the UserDefaults the views already read.
// ponytail: apply on save and on activate; no file watcher. Add one if edits from outside lag.

import SwiftUI

enum Config {
    static let defaults: [String: Any] = [
        "fontSize": 15.0, "tabWidth": 4.0, "monospaced": false, "model": "qwen2.5-coder:1.5b-base",
        "formatOnSave": false, "keywordColor": "#FF2D55", "stringColor": "#34C759", "numberColor": "#FF9500",
        "commentColor": "#8E8E93", "linkColor": "#007AFF",
    ]

    /// Spaces per tab, 1 to 16. Unset or nonsense means 4.
    static var tabWidth: Int {
        let w = UserDefaults.standard.double(forKey: "tabWidth")
        return w >= 1 && w <= 16 ? Int(w) : 4
    }

    /// "#RRGGBB" from the config, falling back to the default.
    static func color(_ key: String) -> Color {
        parse(UserDefaults.standard.string(forKey: key)) ?? parse(defaults[key] as? String) ?? .primary   // bad hex: default
    }
    private static func parse(_ hex: String?) -> Color? {
        guard let hex, hex.count == 7, hex.hasPrefix("#"), let v = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return Color(red: Double(v >> 16 & 0xff) / 255, green: Double(v >> 8 & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }

    static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Plain")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let u = dir.appendingPathComponent("plain.json")
        if !FileManager.default.fileExists(atPath: u.path) {
            try? JSONSerialization.data(withJSONObject: defaults, options: [.prettyPrinted, .sortedKeys]).write(to: u)
        }
        return u
    }

    /// Apply if `text` is our config (a JSON object with at least one known key). Returns whether it was.
    @discardableResult
    static func apply(_ text: String) -> Bool {
        guard let o = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
              !Set(o.keys).isDisjoint(with: defaults.keys) else { return false }
        for (k, v) in o where defaults[k] != nil {
            // Only take a value of the same shape as the default; a string where a number goes is ignored.
            switch (defaults[k], v) {
            case (is Double, let n as NSNumber): UserDefaults.standard.set(n.doubleValue, forKey: k)
            case (is Bool, let b as Bool): UserDefaults.standard.set(b, forKey: k)
            case (is String, let s as String): UserDefaults.standard.set(s, forKey: k)
            default: continue
            }
        }
        return true
    }

    static func load() { apply((try? String(contentsOf: url, encoding: .utf8)) ?? "") }
}
