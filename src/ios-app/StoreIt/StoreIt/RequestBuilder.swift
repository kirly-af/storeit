//
//  RequestBuilder.swift
//  StoreIt
//
//  Created by Romain Gjura on 20/03/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import ObjectMapper

class RequestBuilder {
    
    init() {}
        
    // REQUESTS
    
    func join(username: String, port: Int, hosted_hashes: [String], file: File) -> String {
        let args: String = "\(username) \(port) \(chunkHashesToStr(hosted_hashes, separator: ":")) \(fileObjectToJSON(file))"
		return "JOIN \(size(args)) \(args)"
    }
    
    // TOOLS
    
    private func fileObjectToJSON(file: File) -> String {
        return Mapper().toJSONString(file)!
    }
    
    private func size(str: String) -> Int {
        return str.characters.count
    }
    
    private func chunkHashesToStr(chunk_hashes: [String], separator: String) -> String {
        return chunk_hashes.isEmpty ? "None" : chunk_hashes.joinWithSeparator(separator)
    }
}