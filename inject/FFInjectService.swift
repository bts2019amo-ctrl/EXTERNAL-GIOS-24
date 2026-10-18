import Foundation

enum FFInjectService {
    static let candidateBundleIDs = [
        "com.dts.freefireth",
        "com.dts.freefiremax",
        "com.garena.game.freefire",
        "com.dts.freefireth.max",
    ]

    static let relativeTargets: [(file: String, paths: [String])] = [
        ("localconfig.json", [
            "Documents/localconfig.json",
            "Library/localconfig.json",
            "Documents/ILFix/localconfig.json",
            "Library/Caches/localconfig.json",
        ]),
        ("Assembly-CSharp-patch.bytes", [
            "Documents/Assembly-CSharp-patch.bytes",
            "Library/Assembly-CSharp-patch.bytes",
            "Documents/ILFix/Assembly-CSharp-patch.bytes",
            "Library/Caches/Assembly-CSharp-patch.bytes",
            "Documents/IFix/Assembly-CSharp-patch.bytes",
        ]),
    ]

    struct Result {
        var messages: [String] = []
        var successCount: Int = 0
        var failCount: Int = 0
    }

    static func download(from baseURLString: String) async throws -> (bytes: Data, config: Data) {
        let trimmed = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let base = URL(string: trimmed), base.scheme?.lowercased() == "https" else {
            throw InjectError.invalidURL
        }

        let bytesURL = base.appendingPathComponent("Assembly-CSharp-patch.bytes")
        let configURL = base.appendingPathComponent("localconfig.json")

        let session = URLSession(configuration: .ephemeral)
        async let bytesData = session.data(from: bytesURL)
        async let configData = session.data(from: configURL)

        let (b, br) = try await bytesData
        let (c, cr) = try await configData

        guard let bh = br as? HTTPURLResponse, (200..<300).contains(bh.statusCode), !b.isEmpty else {
            throw InjectError.downloadFailed("Assembly-CSharp-patch.bytes")
        }
        guard let ch = cr as? HTTPURLResponse, (200..<300).contains(ch.statusCode), !c.isEmpty else {
            throw InjectError.downloadFailed("localconfig.json")
        }
        return (b, c)
    }

    static func inject(bytes: Data, config: Data) -> Result {
        var result = Result()

        guard KernelExploit.hasSandboxAccess() || KernelExploit.run() else {
            result.messages.append("EXPLOIT FAILED — cannot write into Free Fire")
            result.failCount += 1
            return result
        }
        result.messages.append("EXPLOIT OK")

        var resolved: [(bundleID: String, root: URL)] = []
        for bid in candidateBundleIDs {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bid),
               ContainerStore.isApplicationContainerPath(path) {
                let root = URL(fileURLWithPath: path, isDirectory: true)
                resolved.append((bid, root))
                result.messages.append("FOUND \(bid)")
            }
        }

        if resolved.isEmpty {
            result.messages.append("NO FREE FIRE CONTAINER — install FF / FF MAX first")
            result.failCount += 1
            return result
        }

        let payload: [(name: String, data: Data, paths: [String])] = [
            ("localconfig.json", config, relativeTargets[0].paths),
            ("Assembly-CSharp-patch.bytes", bytes, relativeTargets[1].paths),
        ]

        let fm = FileManager.default
        for (bid, root) in resolved {
            for item in payload {
                var wrote = false
                for rel in item.paths {
                    let dest = root.appendingPathComponent(rel)
                    let dir = dest.deletingLastPathComponent()
                    do {
                        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                        try item.data.write(to: dest, options: [.atomic])
                        result.messages.append("OK \(bid) → \(rel)")
                        result.successCount += 1
                        wrote = true
                    } catch {
                    }
                }
                if !wrote {
                    result.messages.append("FAIL \(bid) \(item.name)")
                    result.failCount += 1
                }
            }
        }
        return result
    }
}

enum InjectError: Error, LocalizedError {
    case invalidURL
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida — use https://..."
        case .downloadFailed(let f): return "Falha ao baixar \(f)"
        }
    }
}
