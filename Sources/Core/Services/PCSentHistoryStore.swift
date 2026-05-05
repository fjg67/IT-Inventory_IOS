import Foundation

protocol PCSentHistoryStore {
    func fetch() -> [PCSentHistoryRecord]
    func add(_ record: PCSentHistoryRecord)
}

final class UserDefaultsPCSentHistoryStore: PCSentHistoryStore {
    private let defaults: UserDefaults
    private let key = "pc_sent_history_records"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() -> [PCSentHistoryRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PCSentHistoryRecord].self, from: data)) ?? []
    }

    func add(_ record: PCSentHistoryRecord) {
        var all = fetch()
        all.insert(record, at: 0)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(all) {
            defaults.set(data, forKey: key)
        }
    }
}
