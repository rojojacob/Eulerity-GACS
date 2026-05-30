//
//  FormLoadError.swift
//  Eulerity
//

import Foundation

/// Every way loading the bundled form payload can fail, as a typed, closed set.
/// The UI maps one of these to a friendly error state instead of crashing
/// (Constitution V; Plan.md B3).
nonisolated enum FormLoadError: Error, Equatable, Sendable {
    /// The resource was not found in the bundle.
    case fileNotFound(resource: String)
    /// The file existed but could not be read.
    case unreadable(message: String)
    /// The file was read but its top-level JSON could not be decoded.
    case decoding(message: String)
}

extension FormLoadError: LocalizedError {
    nonisolated var errorDescription: String? {
        switch self {
        case .fileNotFound(let resource):
            return "Couldn't find \"\(resource).json\" in the app bundle."
        case .unreadable(let message):
            return "Couldn't read the form file. \(message)"
        case .decoding(let message):
            return "The form file isn't valid. \(message)"
        }
    }
}
