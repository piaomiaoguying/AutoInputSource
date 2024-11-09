//
//  InputSourcesManager.swift
//  AutoInputSource
//
//  Created by 梁波 on 2024/3/18.
//

import Foundation
import Carbon


// "com.apple.keylayout.ABC" -> ["英文"]
class InputSourcesManager {
    static let shared = InputSourcesManager()
    private let defaults = UserDefaults.standard
    private let inputSourcesKey = "InputSourcesDictionary"

    private init() {}

    //    将输入法字典存储在UserDefaults中
    func saveInputSourcesDictionary(_ inputSourcesDictionary: [String: String]) {
        defaults.set(inputSourcesDictionary, forKey: inputSourcesKey)
    }

    //    从UserDefaults中检索输入法字典
    func loadInputSourcesDictionary() -> [String: String]? {
        if let data = UserDefaults.standard.data(forKey: inputSourcesKey) {
            do {
                let dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? [String: String]
                return dictionary
            } catch {
                Logger.error("解档失败：\(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    //向输入法字典中添加新的输入法
    func addInputSource(name: String, identifier: String) {
        var inputSourcesDictionary = loadInputSourcesDictionary() ?? [:]
        inputSourcesDictionary[name] = identifier
        saveInputSourcesDictionary(inputSourcesDictionary)
    }
    //从输入法字典中移除指定的输入法
    func removeInputSource(name: String) {
        var inputSourcesDictionary = loadInputSourcesDictionary() ?? [:]
        inputSourcesDictionary.removeValue(forKey: name)
        saveInputSourcesDictionary(inputSourcesDictionary)
    }
    //更新输入法字典中指定输入法的标识符。
    func updateInputSource(name: String, identifier: String) {
        var inputSourcesDictionary = loadInputSourcesDictionary() ?? [:]
        inputSourcesDictionary[name] = identifier
        saveInputSourcesDictionary(inputSourcesDictionary)
    }
}


//"com.apple.keylayout.ABC" -> <TSMInputSource 0x600002b38480> KB Layout: ABC (id=252)
class TISInputSourceManager {
    static let shared = TISInputSourceManager()
    private let defaults = UserDefaults.standard
    private let tisInputSourcesKey = "TISInputSourcesDictionary"

    private init() {}

    // 将输入法ID存储在 UserDefaults 中
    func saveTISInputSourcesDictionary(_ tisInputSourcesDictionary: [String: String]) {
        defaults.set(tisInputSourcesDictionary, forKey: tisInputSourcesKey)
    }
      
    // 从 UserDefaults 中检索输入法ID，并转换为 TISInputSource
    func loadTISInputSourcesDictionary() -> [String: TISInputSource]? {
        guard let savedDictionary = defaults.dictionary(forKey: tisInputSourcesKey) as? [String: String] else {
            return nil
        }
        
        var result: [String: TISInputSource] = [:]
        
        // 获取所有可用的输入法
        if let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] {
            for inputSource in inputSourceList {
                if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                    let id = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
                    // 如果这个输入法在保存的字典中，就添加到结果中
                    if savedDictionary.values.contains(id) {
                        for (key, value) in savedDictionary {
                            if value == id {
                                result[key] = inputSource
                            }
                        }
                    }
                }
            }
        }
        
        return result
    }

    // 向 TISInputSource 字典中添加新的输入法
    func addTISInputSource(name: String, inputSource: TISInputSource) {
        var tisInputSourcesDictionary = defaults.dictionary(forKey: tisInputSourcesKey) as? [String: String] ?? [:]
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let id = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            tisInputSourcesDictionary[name] = id
            saveTISInputSourcesDictionary(tisInputSourcesDictionary)
        }
    }

    // 从 TISInputSource 字典中移除指定的输入法
    func removeTISInputSource(name: String) {
        var tisInputSourcesDictionary = defaults.dictionary(forKey: tisInputSourcesKey) as? [String: String] ?? [:]
        tisInputSourcesDictionary.removeValue(forKey: name)
        saveTISInputSourcesDictionary(tisInputSourcesDictionary)
    }

    // 更新 TISInputSource 字典中指定输入法的值
    func updateTISInputSource(name: String, inputSource: TISInputSource) {
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            var tisInputSourcesDictionary = defaults.dictionary(forKey: tisInputSourcesKey) as? [String: String] ?? [:]
            let id = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            tisInputSourcesDictionary[name] = id
            saveTISInputSourcesDictionary(tisInputSourcesDictionary)
        }
    }
}


//["英文"] -> <TSMInputSource 0x600002b38480> KB Layout: ABC (id=252)
//class IMEInputSourceManager {
//    static let shared = IMEInputSourceManager()
//    private let defaults = UserDefaults.standard
//    private let imeInputSourcesKey = "IMEInputSourcesDictionary"
//
//    private init() {}
//
//    // 将 IMEInputSource 字典存储在 UserDefaults 中
//    func saveIMEInputSourcesDictionary(_ imeInputSourcesDictionary: [String: TISInputSource]) {
//        let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: imeInputSourcesDictionary, requiringSecureCoding: false)
//        defaults.set(encodedData, forKey: imeInputSourcesKey)
//    }
//
//    // 从 UserDefaults 中检索 IMEInputSource 字典
//    func loadIMEInputSourcesDictionary() -> [String: TISInputSource]? {
//        if let encodedData = defaults.data(forKey: imeInputSourcesKey) {
//            return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(encodedData) as? [String: TISInputSource]
//        }
//        return nil
//    }
//
//    // 向 IMEInputSource 字典中添加新的输入法
//    func addIMEInputSource(name: String, inputSource: TISInputSource) {
//        var imeInputSourcesDictionary = loadIMEInputSourcesDictionary() ?? [:]
//        imeInputSourcesDictionary[name] = inputSource
//        saveIMEInputSourcesDictionary(imeInputSourcesDictionary)
//    }
//
//    // 从 IMEInputSource 字典中移除指定的输入法
//    func removeIMEInputSource(name: String) {
//        var imeInputSourcesDictionary = loadIMEInputSourcesDictionary() ?? [:]
//        imeInputSourcesDictionary.removeValue(forKey: name)
//        saveIMEInputSourcesDictionary(imeInputSourcesDictionary)
//    }
//
//    // 更新 IMEInputSource 字典中指定输入法的值
//    func updateIMEInputSource(name: String, inputSource: TISInputSource) {
//        var imeInputSourcesDictionary = loadIMEInputSourcesDictionary() ?? [:]
//        imeInputSourcesDictionary[name] = inputSource
//        saveIMEInputSourcesDictionary(imeInputSourcesDictionary)
//    }
//}



class IMEInputSourceManager {
    static let shared = IMEInputSourceManager()
    
    // Dictionary to store TISInputSource instances
    private var imeInputSourcesDictionary: [String: TISInputSource] = [:]
    
    private init() {}
    
    // Add a TISInputSource to the dictionary
    func addIMEInputSource(name: String, inputSource: TISInputSource) {
        imeInputSourcesDictionary[name] = inputSource
    }
    
    // Remove a TISInputSource from the dictionary
    func removeIMEInputSource(name: String) {
        imeInputSourcesDictionary.removeValue(forKey: name)
    }
    
    // Get a TISInputSource from the dictionary
    func getIMEInputSource(name: String) -> TISInputSource? {
        return imeInputSourcesDictionary[name]
    }
    
    // Update a TISInputSource in the dictionary
    func updateIMEInputSource(name: String, inputSource: TISInputSource) {
        imeInputSourcesDictionary[name] = inputSource
    }
}



// 通用的字典方法
class KeyValueStore<T: Codable> {
    private let defaults = UserDefaults.standard

    func saveValue(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }

    func loadValue(forKey key: String) -> T? {
        if let savedValue = defaults.object(forKey: key) as? Data {
            let decoder = JSONDecoder()
            if let loadedValue = try? decoder.decode(T.self, from: savedValue) {
                return loadedValue
            }
        }
        return nil
    }
    
    func updateValue(_ value: T, forKey key: String) {
        saveValue(value, forKey: key)
    }
    
    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
