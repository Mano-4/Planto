import Foundation

struct Planto: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var room: Room
    var light: Light
    var wateringDays: WateringDays
    var waterAmount: WaterAmount
}

enum Room: String, CaseIterable, Codable, Identifiable {
    case bedroom = "Bedroom"
    case livingRoom = "Living Room"
    case kitchen = "Kitchen"
    case balcony = "Balcony"
    case bathroom = "Bathroom"

    var id: String { rawValue }
}

enum Light: String, CaseIterable, Codable, Identifiable {
    case fullSun = "Full Sun"
    case partialSun = "Partial Sun"
    case lowLight = "Low Light"

    var id: String { rawValue }
}

enum WateringDays: String, CaseIterable, Codable, Identifiable {
    case everyDay = "Every day"
    case every2Days = "Every 2 days"
    case every3Days = "Every 3 days"
    case onceAWeek = "Once a week"
    case every10Days = "Every 10 days"
    case every2Weeks = "Every 2 weeks"

    var id: String { rawValue }

    var numberOfDays: Int {
        switch self {
        case .everyDay: return 1
        case .every2Days: return 2
        case .every3Days: return 3
        case .onceAWeek: return 7
        case .every10Days: return 10
        case .every2Weeks: return 14
        }
    }

    var interval: TimeInterval {
        TimeInterval(numberOfDays * 24 * 60 * 60)
    }
}

enum WaterAmount: String, CaseIterable, Codable, Identifiable {
    case ml20To50 = "20–50 ml"
    case ml50To100 = "50–100 ml"
    case ml100To200 = "100–200 ml"
    case ml200To300 = "200–300 ml"

    var id: String { rawValue }
}
