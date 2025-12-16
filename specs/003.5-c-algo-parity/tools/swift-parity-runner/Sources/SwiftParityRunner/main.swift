import Foundation

func run() throws {
    let options = try CLIParser().parse()
    let startedAt = Date()
    let platform = PlatformDetector.detect()
    let corpus = try CorpusParser().parse(url: URL(fileURLWithPath: options.corpusPath))
    let reference = try ReferenceLoader().load(path: options.referencePath)

    let bridge = ComparisonBridge(tolerance: .default)
    let (caseResults, deltaEValues) = try bridge.runComparisons(corpus: corpus, reference: reference, options: options)

    let generator = ReportGenerator()
    let finishedAt = Date()
    let (report, artifactsRoot) = generator.generate(
        runId: options.runId,
        corpus: corpus,
        results: caseResults,
        allDeltaE: deltaEValues,
        options: options,
        startedAt: startedAt,
        finishedAt: finishedAt,
        platform: platform
    )
    let reportURL = try generator.write(report: report, to: artifactsRoot)
    let formattedPassRate = String(format: "%.3f", report.passRate)
    print("swift-parity-runner completed. Pass rate: \(formattedPassRate). Report: \(reportURL.path)")

    if !report.withinPassGate {
        exit(2)
    }
}

do {
    try run()
} catch let error as CLIError {
    fputs("Error: \(error.message)\n", stderr)
    CLIParser.printUsage()
    exit(1)
} catch {
    fputs("Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}

// MARK: - CLI

enum CLIError: Error {
    case missingValue(String)
    case unknownFlag(String)
    case missingRequired(String)

    var message: String {
        switch self {
        case .missingValue(let flag):
            return "Missing value for flag \(flag)"
        case .unknownFlag(let flag):
            return "Unknown flag \(flag)"
        case .missingRequired(let name):
            return "Missing required argument: \(name)"
        }
    }
}

struct CLIParser {
    func parse() throws -> CLIOptions {
        var corpusPath: String?
        var referencePath: String?
        var artifactsPath = "specs/005-c-algo-parity/artifacts/swift-parity"
        var caseFilter: Set<String>?
        var tagFilter: Set<String>?
        var passGate = 0.95
        var runId: String?
        var swiftVersion: String?
        var targetSDK: String?

        var iterator = CommandLine.arguments.dropFirst().makeIterator()
        while let arg = iterator.next() {
            switch arg {
            case "--corpus":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                corpusPath = value
            case "--c-reference":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                referencePath = value
            case "--artifacts":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                artifactsPath = value
            case "--cases":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                let ids = value.split(separator: ",").map { String($0) }
                caseFilter = Set(ids)
            case "--tags":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                let tags = value.split(separator: ",").map { String($0) }
                tagFilter = Set(tags)
            case "--pass-gate":
                guard let value = iterator.next(), let threshold = Double(value) else { throw CLIError.missingValue(arg) }
                passGate = threshold
            case "--run-id":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                runId = value
            case "--swift-version":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                swiftVersion = value
            case "--target-sdk":
                guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
                targetSDK = value
            case "--help", "-h":
                CLIParser.printUsage()
                exit(0)
            default:
                if arg.hasPrefix("--") {
                    throw CLIError.unknownFlag(arg)
                }
            }
        }

        guard let corpus = corpusPath else { throw CLIError.missingRequired("--corpus") }
        guard let reference = referencePath else { throw CLIError.missingRequired("--c-reference") }
        guard passGate >= 0 && passGate <= 1 else { throw CLIError.missingRequired("--pass-gate must be between 0 and 1") }

        let resolvedRunId = runId ?? Self.defaultRunId()
        let resolvedSwiftVersion = swiftVersion ?? SwiftVersionDetector.detect()

        return CLIOptions(
            corpusPath: corpus,
            referencePath: reference,
            artifactsPath: artifactsPath,
            caseFilter: caseFilter,
            tagFilter: tagFilter,
            passGate: passGate,
            runId: resolvedRunId,
            swiftVersion: resolvedSwiftVersion,
            targetSDK: targetSDK
        )
    }

    static func printUsage() {
        let usage = """
        swift-parity-runner
        Usage:
          swift-parity-runner --corpus <file> --c-reference <file> [options]
        Options:
          --artifacts <dir>       Output directory for artifacts (default: specs/005-c-algo-parity/artifacts/swift-parity)
          --cases <id1,id2>       Comma-separated case IDs to run
          --tags <tag1,tag2>      Comma-separated tag filters
          --pass-gate <0-1>       Pass rate threshold (default: 0.95)
          --run-id <id>           Custom run identifier
          --swift-version <ver>   Override detected Swift version
          --target-sdk <name>     Optional target SDK label
          --help, -h              Show this help message
        """
        print(usage)
    }

    private static func defaultRunId() -> String {
        let formatter = ISO8601DateFormatter()
        let raw = formatter.string(from: Date())
        let sanitized = raw.replacingOccurrences(of: ":", with: "-")
        return "swift-parity-\(sanitized)"
    }
}

struct SwiftVersionDetector {
    static func detect() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "-version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return "unknown"
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.split(separator: "\n").first {
            return String(output)
        }
        return "unknown"
    }
}

struct PlatformDetector {
    static func detect() -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let host = Host.current().localizedName ?? "unknown-host"
        return "\(host) | \(os)"
    }
}
