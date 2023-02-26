//
//  AppFileManager.swift
//  fotoplay
//
//  Created by ysunwill on 2022/7/20.
//

import Foundation

public enum CommonDirectory {
    case documents
    case library
    case caches
    case tmp
}

protocol CommonDirectoryName {
    func documentsDirectoryURL() -> URL
    func libraryDirectoryURL() -> URL
    func cachesDirectoryURL() -> URL
    func tmpDirectoryURL() -> URL
    func getURL(for directory: CommonDirectory) -> URL
}

extension CommonDirectoryName {
    func documentsDirectoryURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func libraryDirectoryURL() -> URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
    }
    
    func cachesDirectoryURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    func tmpDirectoryURL() -> URL {
        return FileManager.default.temporaryDirectory
    }
    
    func getURL(for directory: CommonDirectory) -> URL {
        switch directory {
        case .documents:
            return documentsDirectoryURL()
        case .library:
            return libraryDirectoryURL()
        case .caches:
            return cachesDirectoryURL()
        case .tmp:
            return tmpDirectoryURL()
        }
    }
}

public class AppFileManager: CommonDirectoryName {
    // 单例
    static let shared = AppFileManager()
    
    // MARK: - Life Cycle
    
    private init() { }

    // MARK: - Interface
    
    /// 查询文件或者文件夹是否存在
    /// - Parameter url: 文件或者文件夹的url
    /// - Returns: 查询结果
    public func fileOrDirectoryExists(at url: URL) -> Bool {
        let pathString = url.path
        return FileManager.default.fileExists(atPath: pathString)
    }
    
    /// 创建文件夹，在指定目录下创建
    /// 注意：如果已存在文件夹，不会覆盖创建，保留现有文件夹
    /// - Parameters:
    ///   - url: 指定目录url
    ///   - directoryName: 文件夹名称
    /// - Returns: 创建结果
    public func createCustomDirectory(at url: URL, with directoryName: String) -> Bool {
        let directoryURL = url.appendingPathComponent(directoryName)
        return createCustomDirectory(at: directoryURL)
    }
    
    /// 创建文件夹，直接在 Document 、Library、Library/Caches、tmp 根目录下创建
    /// 注意：如果已存在文件夹，不会覆盖创建，保留现有文件夹
    /// - Parameters:
    ///   - commonDirectory: 沙盒四大目录
    ///   - directoryName: 文件夹名称
    /// - Returns: 创建结果
    public func createCustomDirectory(in commonDirectory: CommonDirectory, with directoryName: String) -> Bool {
        let directoryURL = getURL(for: commonDirectory).appendingPathComponent(directoryName)
        return createCustomDirectory(at: directoryURL)
    }
    
    /// 文件写到沙盒指定目录下
    /// - Parameters:
    ///   - data: 文件内容
    ///   - url: 指定目录
    ///   - fileName: 文件名称
    /// - Returns: 文件写入结果
    public func writeFile(data: Data?, at url: URL, with fileName: String) -> Bool {
        let filePath = url.path + "/" + fileName
        return FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    
    /// 文件写到沙盒 Document 、Library、Library/Caches、tmp 的根目录下
    /// - Parameters:
    ///   - data: 文件内容
    ///   - directory: 沙盒四大目录
    ///   - fileName: 文件名称
    /// - Returns: 文件写入结果
    public func writeFile(data: Data?, in directory: CommonDirectory, with fileName: String) -> Bool {
        let filePath = getURL(for: directory).path + "/" + fileName
        return FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    
    /// 读取 Document 、Library、Library/Caches、tmp 根目录下的文件
    /// 注意：如果文件不存在，返回nil
    /// - Parameters:
    ///   - directory: 沙盒四大目录
    ///   - fileName: 文件名称
    /// - Returns: 文件内容的字符串，utf-8编码
    public func readFile(at url: URL, with fileName: String) -> String? {
        let filePath = url.path + "/" + fileName
        return readFile(at: filePath)
    }
    
    /// 读取指定目录下的文件
    /// 注意：如果文件不存在，返回nil
    /// - Parameters:
    ///   - url: 指定目录
    ///   - fileName: 文件名称
    /// - Returns: 文件内容的字符串，utf-8编码
    public func readFile(in directory: CommonDirectory, with fileName: String) -> String? {
        let filePath = getURL(for: directory).path + "/" + fileName
        return readFile(at: filePath)
    }
    
    // MARK: - Private Functions
    
    /// 创建文件夹
    public func createCustomDirectory(at url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        return true
    }
    
    /// 读取文件
    private func readFile(at path: String) -> String? {
        if FileManager.default.isReadableFile(atPath: path) {
            if let fileData = FileManager.default.contents(atPath: path),
               let fileString = String(bytes: fileData, encoding: .utf8)
            {
                return fileString
            }
            
            return nil
        } else {
            return nil
        }
    }
    
    public func removeFile(at URL: URL) {
        do {
            try FileManager.default.removeItem(at: URL)
        } catch {
            print(error.localizedDescription)
        }
    }
}

