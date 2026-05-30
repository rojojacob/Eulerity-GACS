//
//  Models.swift
//  Eulerity
//
//  Domain models for the decoded form payload live in this folder: pure,
//  `Decodable`, `Sendable` value types with NO `import SwiftUI` (Constitution I,
//  Plan.md §4 boundary rules).
//
//  Built during Phase B/C (Plan.md §6):
//    • FormPayload     — top-level: theme, form_title, fields
//    • FormField       — flat struct of shared + optional type-specific keys + computed `kind`
//    • FieldType       — TEXT / DROPDOWN / TOGGLE / CHECKBOX / .unsupported(rawValue:)
//    • TextSubtype     — PLAIN / MULTILINE / NUMBER / URI / SECURE
//    • DropdownOption  — { id, label }
//    • ThemeModel      — raw hex strings
//    • FieldValue      — enum: .text(String) / .bool(Bool) / .selection([String])
//
//  Intentionally empty in the skeleton.
//
