import Foundation

struct ReportGenerator {
    func generate(
        runId: String,
        corpus: CorpusFile,
        results: [CaseResult],
        allDeltaE: [Double],
        options: CLIOptions,
        startedAt: Date,
        finishedAt: Date,
        platform: String
    ) -> (RunReport, URL) {
        let passCount = results.filter { $0.passed }.count
        let total = results.count
        let failCount = total - passCount
        let passRate = total > 0 ? Double(passCount) / Double(total) : 0
        let withinPassGate = passRate >= options.passGate

        let stats = summarize(allDeltaE)

        let summary = RunSummary(
            totalCases: total,
            passed: passCount,
            failed: failCount,
            passRate: passRate,
            deltaE: stats
        )

        let artifactsRoot = URL(fileURLWithPath: options.artifactsPath)
            .appendingPathComponent(runId, isDirectory: true)

        let provenance = Provenance(
            corpusVersion: corpus.corpusVersion,
            swiftVersion: options.swiftVersion,
            targetSDK: options.targetSDK,
            platform: platform,
            referencePath: options.referencePath
        )

        let report = RunReport(
            runId: runId,
            corpusVersion: corpus.corpusVersion,
            state: withinPassGate ? "completed" : "failed",
            passGate: options.passGate,
            passRate: passRate,
            durationMs: finishedAt.timeIntervalSince(startedAt) * 1000,
            startedAt: iso8601(startedAt),
            finishedAt: iso8601(finishedAt),
            withinPassGate: withinPassGate,
            summary: summary,
            cases: results,
            provenance: provenance,
            artifactsRoot: artifactsRoot.path
        )

        return (report, artifactsRoot)
    }

    func write(report: RunReport, to artifactsRoot: URL) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: artifactsRoot, withIntermediateDirectories: true)
        let reportURL = artifactsRoot.appendingPathComponent("report.json")
        let data = try JSONEncoder().encode(report)
        try data.write(to: reportURL)
        return reportURL
    }

    private func summarize(_ values: [Double]) -> SummaryStats {
        guard !values.isEmpty else {
            return SummaryStats(mean: 0, stddev: 0, p50: 0, p95: 0, p99: 0, min: 0, max: 0)
        }

        let sorted = values.sorted()
        let meanValue = mean(values)
        let stddevValue = stddev(values, mean: meanValue)

        return SummaryStats(
            mean: meanValue,
            stddev: stddevValue,
            p50: percentile(sorted, 0.50),
            p95: percentile(sorted, 0.95),
            p99: percentile(sorted, 0.99),
            min: sorted.first ?? 0,
            max: sorted.last ?? 0
        )
    }

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }

    private func stddev(_ values: [Double], mean: Double) -> Double {
        guard values.count > 1 else { return 0 }
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance)
    }

    private func percentile(_ sortedValues: [Double], _ quantile: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }
        let position = quantile * Double(sortedValues.count - 1)
        let lower = Int(floor(position))
        let upper = Int(ceil(position))
        if lower == upper { return sortedValues[lower] }
        let weight = position - Double(lower)
        return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight
    }

    private func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
