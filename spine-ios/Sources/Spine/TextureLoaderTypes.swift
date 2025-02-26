import Foundation
import SpineCppLite

// Define the texture loader function types
public typealias TextureLoaderLoadFunc = @convention(c) (UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?
public typealias TextureLoaderUnloadFunc = @convention(c) (UnsafeMutableRawPointer?) -> Void
