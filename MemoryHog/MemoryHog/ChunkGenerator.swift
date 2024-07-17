//
// Created by Joey Jarosz on 5/24/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import UIKit

///
enum ChunkGeneratorError: LocalizedError {
    case allocationRequestTooLarge
    
    public var errorDescription: String? {
        switch self {
        case .allocationRequestTooLarge:
            return NSLocalizedString("Requested memory consumption would result in a crash.", comment: "")
        }
    }
}

/// This `singleton` is used to consume memory inside the app. The numbers reporting the total memory, available memory, and used memory are not precise so do
/// not be surprised if you are trying to get right up to the edge that the OS generatea low memory warning.
///
class ChunkGenerator {
    typealias Chunk = [Int8]
    typealias Chunks = [Chunk]

    static let defaultNumberOfChunks = 1
    static let defaultSizeOfChunksInBytes = Measurement<UnitInformationStorage>(value: 100, unit: .megabytes).converted(to: .bytes).value
    
    static var shared = ChunkGenerator()
    
    private var store: [Chunks] = []
       
    // MARK: - Initializers
    
    private init() { }
    
    // MARK: Internal Methods
    
    /// Allocates memory as requested
    ///
    /// - Parameters:
    ///   - numberOfChunks: The number of "chunks" of memory to allocate,  here just for orgaizational purposes
    ///   - sizeOfChunksInBytes: The number of bytes in each "chunk" to be allocated
    ///
    func generate(numberOfChunks: Int, sizeOfChunksInBytes: Int) async throws {
        guard (Self.availableCapacityInBytes > UInt64(numberOfChunks * sizeOfChunksInBytes)) else {
            throw ChunkGeneratorError.allocationRequestTooLarge
        }
                
        var chunks: Chunks = []
        
        for _ in 0..<numberOfChunks {
            let chunk = Array<Int8>(repeating: 1, count: sizeOfChunksInBytes)
            chunks.append(chunk)
        }
        
        store.append(chunks)
    }
    
    /// Clear some memory
    ///
    /// - Parameter count: If 0 then it clears all the memory we allocated; else it clears this number of chunks starting with the most recently allocated
    ///
    func removeChunks(_ count: Int? = nil) {
        if let count {
            for _ in 0..<count {
                store.remove(at: store.count - 1)
            }
        }
        else {
            store = []
        }
    }
    
    // MARK: - Our Memory Usage
    
    /// The amount of memory requested to be allocated by the app. Does not include the memory used by the app itself.
    func memoryHogged() ->  Double {
        var size: Int64 = 0
        
        for chunks in store {
            for chunk in chunks {
                size += Int64(chunk.count)
            }
        }
        
        return Double(size)
    }
    
    // MARK: - Utilities
    
    static var availableCapacityInBytes: UInt64 {
        return totalSystemMemoryInBytes - usedMemoryInBytes
    }
    
    static var totalSystemMemoryInBytes: UInt64 {
        ProcessInfo().physicalMemory
    }
    
    /// This is just one way to calculate used memory 
    static var usedMemoryInBytes: UInt64 {
        var usedMemory: UInt64 = 0
        let hostPort: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        var pagesize:vm_size_t = 0
        
        host_page_size(hostPort, &pagesize)
        
        var vmStat: vm_statistics = vm_statistics_data_t()
        let capacity = MemoryLayout.size(ofValue: vmStat) / MemoryLayout<Int32>.stride

        let status: kern_return_t = withUnsafeMutableBytes(of: &vmStat) {
        
        let boundPtr = $0.baseAddress?.bindMemory( to: Int32.self, capacity: capacity )
                   return host_statistics(hostPort, HOST_VM_INFO, boundPtr, &host_size)
        }
              
        if status == KERN_SUCCESS {
            usedMemory = (UInt64)((vm_size_t)(vmStat.active_count + vmStat.inactive_count + vmStat.wire_count) * pagesize)
            return usedMemory
        } else {
            return 0
        }
    }
}
