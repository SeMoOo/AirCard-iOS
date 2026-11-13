import Foundation

/// Non-exploit preflight checks for evaluating a future worse_query backend.
/// Does not grant sandbox access or change the app's active Airlift backend.
struct WorseQueryPreflight {
    enum Status: Equatable {
        case unsupportedOS
        case appGroupNotConfigured
        case appGroupUnavailable
        case prerequisitesPresent
    }

    let status: Status
    let osMajorVersion: Int
    let configuredAppGroup: String?

    /// Prerequisites are not proof that the sandbox escape is available.
    var isBackendImplemented: Bool { false }

    static func evaluate(
        osMajorVersion: Int,
        configuredAppGroup: String?,
        hasGroupContainer: Bool
    ) -> WorseQueryPreflight {
        let group = configuredAppGroup?.trimmingCharacters(in: .whitespacesAndNewlines)
        let status: Status
        if osMajorVersion != 26 && osMajorVersion != 27 {
            status = .unsupportedOS
        } else if group?.hasPrefix("group.") != true {
            status = .appGroupNotConfigured
        } else if !hasGroupContainer {
            status = .appGroupUnavailable
        } else {
            status = .prerequisitesPresent
        }
        return WorseQueryPreflight(status: status, osMajorVersion: osMajorVersion, configuredAppGroup: group)
    }

    /// Reads a user-supplied App Group identifier from Info.plist and checks
    /// whether the signed app has a container for that group. Does not open
    /// private or out-of-container paths.
    static func inspect(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo,
        fileManager: FileManager = .default
    ) -> WorseQueryPreflight {
        let groupID = bundle.object(forInfoDictionaryKey: "WorseQueryAppGroupID") as? String
        let available = groupID.flatMap { fileManager.containerURL(forSecurityApplicationGroupIdentifier: $0) } != nil
        return evaluate(
            osMajorVersion: processInfo.operatingSystemVersion.majorVersion,
            configuredAppGroup: groupID,
            hasGroupContainer: available
        )
    }
}
