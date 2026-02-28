import AppKit
import SwiftUI

enum CIStatus: String, Codable, CaseIterable {
    case success
    case failure
    case running
    case unknown

    var sfSymbol: String {
        switch self {
        case .success:  return "checkmark.circle"
        case .failure:  return "xmark.circle"
        case .running:  return "arrow.triangle.2.circlepath"
        case .unknown:  return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .success:  return .green
        case .failure:  return .red
        case .running:  return .orange
        case .unknown:  return .gray
        }
    }

    var nsColor: NSColor {
        switch self {
        case .success:  return .systemGreen
        case .failure:  return .systemRed
        case .running:  return .systemOrange
        case .unknown:  return .systemGray
        }
    }

    var label: String {
        switch self {
        case .success:  return "Passing"
        case .failure:  return "Failing"
        case .running:  return "Running"
        case .unknown:  return "Unknown"
        }
    }

    /// Menu bar icon — uses distinct shapes so template rendering works without color.
    var menuBarSymbol: String {
        switch self {
        case .success:  return "checkmark.diamond"
        case .failure:  return "xmark.diamond"
        case .running:  return "hourglass"
        case .unknown:  return "minus.diamond"
        }
    }

    /// Aggregate multiple statuses: any running → running, else any failure → failure,
    /// else all success → success, else unknown.
    static func aggregate(_ statuses: [CIStatus]) -> CIStatus {
        guard !statuses.isEmpty else { return .unknown }
        if statuses.contains(.running) { return .running }
        if statuses.contains(.failure) { return .failure }
        if statuses.allSatisfy({ $0 == .success }) { return .success }
        return .unknown
    }
}
