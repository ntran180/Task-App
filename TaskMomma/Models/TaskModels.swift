import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

private func intFromFirestore(_ value: Any?) -> Int? {
    if let int = value as? Int { return int }
    if let num = value as? NSNumber { return num.intValue }
    return nil
}

private func dateFromFirestore(_ value: Any?) -> Date? {
    if let date = value as? Date { return date }
    #if canImport(FirebaseFirestore)
    if let ts = value as? Timestamp { return ts.dateValue() }
    #endif
    return nil
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var totalWins: Int
    var onboardedAt: Date?

    init(id: String, displayName: String, totalWins: Int = 0, onboardedAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.totalWins = totalWins
        self.onboardedAt = onboardedAt
    }

    init?(id: String, data: [String: Any]) {
        guard let displayName = data["displayName"] as? String else { return nil }
        self.id = id
        self.displayName = displayName
        self.totalWins = intFromFirestore(data["totalWins"]) ?? 0
        self.onboardedAt = dateFromFirestore(data["onboardedAt"])
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "displayName": displayName,
            "totalWins": totalWins
        ]
        if let onboardedAt {
            data["onboardedAt"] = onboardedAt
        }
        return data
    }
}

struct TaskItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var description: String?
    var durationMinutes: Int
    var categoryId: String?
    var createdAt: Date
    var isArchived: Bool
    var location: TaskLocation?

    init(
        id: String,
        title: String,
        description: String? = nil,
        durationMinutes: Int,
        categoryId: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.durationMinutes = durationMinutes
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    init?(id: String, data: [String: Any]) {
        guard
            let title = data["title"] as? String,
            let durationMinutes = intFromFirestore(data["durationMinutes"])
        else { return nil }

        self.id = id
        self.title = title
        self.description = data["description"] as? String
        self.durationMinutes = durationMinutes
        self.categoryId = data["categoryId"] as? String
        self.createdAt = dateFromFirestore(data["createdAt"]) ?? Date()
        self.isArchived = data["isArchived"] as? Bool ?? false
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "durationMinutes": durationMinutes,
            "createdAt": createdAt,
            "isArchived": isArchived
        ]
        if let description, !description.isEmpty {
            data["description"] = description
        }
        if let categoryId {
            data["categoryId"] = categoryId
        }
        return data
    }
}

struct Win: Identifiable, Codable, Hashable {
    var id: String
    var taskId: String
    var taskTitle: String
    var completedAt: Date
    var durationActual: Int?

    init(
        id: String,
        taskId: String,
        taskTitle: String,
        completedAt: Date = Date(),
        durationActual: Int? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.completedAt = completedAt
        self.durationActual = durationActual
    }

    init?(id: String, data: [String: Any]) {
        guard
            let taskId = data["taskId"] as? String,
            let taskTitle = data["taskTitle"] as? String
        else { return nil }

        self.id = id
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.completedAt = dateFromFirestore(data["completedAt"]) ?? Date()
        self.durationActual = intFromFirestore(data["durationActual"])
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "taskId": taskId,
            "taskTitle": taskTitle,
            "completedAt": completedAt
        ]
        if let durationActual {
            data["durationActual"] = durationActual
        }
        return data
    }
}

struct Category: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var color: String
    var icon: String

    init(id: String, name: String, color: String, icon: String) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
    }

    init?(id: String, data: [String: Any]) {
        guard
            let name = data["name"] as? String,
            let color = data["color"] as? String,
            let icon = data["icon"] as? String
        else { return nil }
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
    }

    var firestoreData: [String: Any] {
        [
            "name": name,
            "color": color,
            "icon": icon
        ]
    }
}

