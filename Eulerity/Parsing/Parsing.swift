//
//  Parsing.swift
//  Eulerity
//
//  Defensive, polymorphic decoding of the bundled JSON. NO `import SwiftUI`.
//  Built during Phase B (Plan.md §6):
//    • FormDecoder — element-by-element Codable decode; unknown `type` →
//      `.unsupported` and a single malformed element is skipped, never aborting
//      the whole payload.
//    • FormLoader  — bundle file → Data → FormPayload, returning a typed
//      `Result<FormPayload, FormLoadError>` (no crashes on missing/corrupt files).
//
//  Intentionally empty in the skeleton.
//
