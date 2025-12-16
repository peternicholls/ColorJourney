import Foundation

struct ReferenceLoader {
    func load(path: String) throws -> [String: [OKLabColor]] {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let report = try decoder.decode(ReferenceReport.self, from: data)
        var map: [String: [OKLabColor]] = [:]
        for entry in report.cases {
            let palette = entry.samples.sorted { $0.index < $1.index }.map {
                OKLabColor(l: $0.canonical.l, a: $0.canonical.a, b: $0.canonical.b)
            }
            map[entry.inputCaseId] = palette
        }
        return map
    }
}
