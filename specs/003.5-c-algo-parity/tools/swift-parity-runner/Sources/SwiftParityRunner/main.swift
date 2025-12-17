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
        var options = CLIOptions(
            corpusPath: "",
            referencePath: "",
            artifactsPath: "specs/005-c-algo-parity/artifacts/swift-parity",
            caseFilter: nil,
            tagFilter: nil,
            passGate: 0.95,
            runId: "",
            swiftVersion: "",
            targetSDK: nil
        )

        var iterator = CommandLine.arguments.dropFirst().makeIterator()
        while let arg = iterator.next() {
            try parseArgument(arg, iterator: &iterator, options: &options)
        }

        try validateOptions(&options)
        return options
    }

    private func parseArgument(_ arg: String, iterator: inout IndexingIterator<[String]>, options: inout CLIOptions) throws {
        switch arg {
        case "--corpus":
            guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
            options.corpusPath = value
        case "--c-reference":
            guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
            options.referencePath = value
        case "--artifacts":
            guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
            options.artifactsPath = value
        case "--cases":
            try parseCasesFilter(iterator: &iterator, options: &options)
        case "--tags":
            try parseTagsFilter(iterator: &iterator, options: &options)
        case "--pass-gate":
            try parsePassGate(iterator: &iterator, options: &options)
        case "--run-id":
            guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
            options.runId = value
        case "--swift-version":
            guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
            options.swiftVersion = value
        case "--target-sdk":
            guard let value = iterator.next() else { throw CLIError.missingValue(arg) }
            options.targetSDK = value
        case "--help", "-h":
            CLIParser.printUsage()
            exit(0)
        default:
            if arg.hasPrefix("--") {
                throw CLIError.unknownFlag(arg)
            }
        }
    }

    private func parseCasesFilter(iterator: inout IndexingIterator<[String]>, options: inout CLIOptions) throws {
        guard let value = iterator.next() else { throw CLIError.missingValue("--cases") }
        let ids = value.split(separator: ",").map { String($0) }
        options.caseFilter = Set(ids)
    }

    private func parseTagsFilter(iterator: inout IndexingIterator<[String]>, options: inout CLIOptions) throws {
        guard let value = iterator.next() else { throw CLIError.missingValue("--tags") }
        let tags = value.split(separator: ",").map { String($0) }
        options.tagFilter = Set(tags)
    }

    private func parsePassGate(iterator: inout IndexingIterator<[String]>, options: inout CLIOptions) throws {
        guard let value = iterator.next(), let threshold = Double(value) else {
            throw CLIError.missingValue("--pass-gate")
        }
        options.passGate = threshold
    }

    private func validateOptions(_ options: inout CLIOptions) throws {
        guard !options.corpusPath.isEmpty else { throw CLIError.missingRequired("--corpus") }
        guard !options.referencePath.isEmpty else { throw CLIError.missingRequired("--c-reference") }
        guard options.passGate >= 0 && options.passGate <= 1 else { throw CLIError.missingRequired("--pass-gate must be between 0 and 1") }

        if options.runId.isEmpty {
            options.runId = Self.defaultRunId()
        }
        if options.swiftVersion.isEmpty {
            options.swiftVersion = SwiftVersionDetector.detect()
        }
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
