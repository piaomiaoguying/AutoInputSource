import Foundation

struct Logger {
    static func debug(_ message: String) {
        #if DEBUG
        print("🔍 Debug: \(message)")
        #endif
    }
    
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ Info: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ Warning: \(message)")
        #endif
    }
    
    static func error(_ message: String) {
        #if DEBUG
        print("❌ Error: \(message)")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ Success: \(message)")
        #endif
    }
} 