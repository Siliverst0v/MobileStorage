# MobileStorage
iOS Developer Tech Task

// Implement mobile phone storage protocol
// Requirements:
// - Mobiles must be unique (IMEI is an unique number)
// - Mobiles must be stored in memory

protocol MobileStorage {
func getAll() -> Set<Mobile>
func findByImei(_ imei: String) -> Mobile?
func save(_ mobile: Mobile) throws -> Mobile
func delete(_ product: Mobile) throws
func exists(_ product: Mobile) -> Bool
}

struct Mobile: Hashable {
let imei: String
let model: String
}
