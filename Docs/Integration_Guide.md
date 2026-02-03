# NailGuard App Integration Guide

## Overview
This guide explains how all components work together using `PersistenceController` as the central data management layer.

## Architecture

### Data Flow
```
PersistenceController (Singleton)
    ↓
ModelContainer (SwiftData)
    ↓
@Query in Views (Auto-updating)
    ↓
UI Updates (Reactive)
```

## Key Components

### 1. PersistenceController.swift
**Purpose**: Centralized SwiftData management
- Singleton pattern (`PersistenceController.shared`)
- Creates and manages the `ModelContainer`
- Provides convenience methods for CRUD operations
- Thread-safe with `@MainActor`

**Usage**:
```swift
// Add a bite event
PersistenceController.shared.addBite()

// Fetch all events
let events = PersistenceController.shared.fetchAllBites()

// Clear all data
PersistenceController.shared.deleteAllBites()
```

### 2. NailGuardApp.swift
**Purpose**: App entry point
- Sets up the ModelContainer at app level
- Creates TabView navigation structure
- Injects `PersistenceController.shared.container` into the view hierarchy

**Key Code**:
```swift
@main
struct NailGuardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
```

### 3. Views with @Query

#### DashboardView.swift
- Uses `@Query` to automatically fetch and observe `BiteEventModel`
- Calculates today's count and weekly data
- Updates reactively when new events are added
- Bar chart scaled to actual event counts (not hardcoded heights)

**Key Features**:
- Real-time today counter
- 7-day bar chart (Sunday to Saturday)
- Auto-updates when data changes via `onChange(of: biteEvents.count)`

#### TrendsView.swift
- Three view modes: Week, Month (Calendar), Year
- Month view shows full calendar with color-coded days
- All data derived from `@Query` on `BiteEventModel`
- Insights auto-generated from event patterns

**Color Coding**:
- Green (1-2): Excellent control
- Yellow (3-5): Good
- Orange (6-8): Needs attention
- Red (9+): High activity
- Gray dot (0): Perfect day!

#### SettingsView.swift
- Shows total event count
- Clear all data button (calls `PersistenceController`)
- Can be extended for user preferences, goals, etc.

## Data Model

### BiteEventModel
```swift
@Model
final class BiteEventModel {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    
    init(id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
    }
}
```

**Note**: Simple design - just timestamps. Each event represents one nail bite occurrence.

## How @Query Works

### Automatic Updates
When you use `@Query` in a SwiftUI view:
```swift
@Query(sort: \BiteEventModel.timestamp, order: .reverse)
private var biteEvents: [BiteEventModel]
```

SwiftUI automatically:
1. Fetches data from the ModelContainer
2. Observes changes to the data
3. Triggers view re-renders when data changes
4. No manual refresh needed!

### Performance
- `@Query` is optimized for SwiftData
- Uses efficient change tracking
- Only re-renders affected views
- Safe to use in List/ForEach with many items

## Adding Events from Watch

When the Watch app syncs events via `WatchConnectivity`:

### iPhone Side (PhoneSyncManager.swift)
```swift
func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    if let timestamp = message["timestamp"] as? Date {
        Task { @MainActor in
            PersistenceController.shared.addBite(timestamp: timestamp)
        }
    }
}
```

### What Happens:
1. Watch sends bite event timestamp
2. `PhoneSyncManager` receives it
3. Calls `PersistenceController.shared.addBite()`
4. Event is inserted into SwiftData
5. All views with `@Query` automatically update
6. Dashboard shows new count
7. Trends updates charts
8. No manual UI refresh needed!

## Testing & Preview

### Preview with Sample Data
Both DashboardView and TrendsView include preview providers with sample data:

```swift
@MainActor
static var previewContainer: ModelContainer = {
    let schema = Schema([BiteEventModel.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)
    
    // Insert sample events
    for i in 0..<30 {
        let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
        let event = BiteEventModel(timestamp: date)
        container.mainContext.insert(event)
    }
    
    return container
}()
```

### Benefits:
- Previews work without real database
- Fast iteration during development
- Realistic sample data
- No side effects on production data

## Common Patterns

### Pattern 1: Read-Only Display
Use `@Query` for views that just display data:
```swift
struct MyView: View {
    @Query private var events: [BiteEventModel]
    
    var body: some View {
        Text("Total: \(events.count)")
    }
}
```

### Pattern 2: Create/Update/Delete
Use `PersistenceController` for data modifications:
```swift
// Create
PersistenceController.shared.addBite()

// Delete
PersistenceController.shared.deleteAllBites()
```

### Pattern 3: Filtered Queries
Query with predicates:
```swift
@Query(
    filter: #Predicate<BiteEventModel> { event in
        event.timestamp >= startDate && event.timestamp <= endDate
    },
    sort: \BiteEventModel.timestamp
)
private var filteredEvents: [BiteEventModel]
```

## Troubleshooting

### Issue: Views not updating
**Solution**: Ensure `.modelContainer()` is applied to root view in app:
```swift
WindowGroup {
    ContentView()
}
.modelContainer(PersistenceController.shared.container)
```

### Issue: Preview crashes
**Solution**: Use in-memory container in preview:
```swift
.modelContainer(for: BiteEventModel.self, inMemory: true)
```

### Issue: Duplicate events
**Solution**: `BiteEventModel.id` has `@Attribute(.unique)` - SwiftData prevents duplicates

### Issue: Watch sync not showing
**Solution**: 
1. Check `PhoneSyncManager` is receiving messages
2. Verify `@MainActor` on `addBite()` call
3. Ensure WCSession is activated

## Best Practices

### ✅ Do:
- Use `PersistenceController.shared` for all data modifications
- Use `@Query` in views for data display
- Keep `PersistenceController` as singleton
- Use `@MainActor` for UI-related operations
- Test with preview containers

### ❌ Don't:
- Create multiple `ModelContainer` instances
- Directly manipulate `ModelContext` from views
- Force unwrap dates (use guard/if let)
- Forget `.modelContainer()` modifier on root view
- Block main thread with heavy data operations

## Next Steps

### Extend Functionality:
1. **Add Goals**: Create `GoalModel` with daily target
2. **Categories**: Add tags/categories to events (e.g., "Work", "Home")
3. **Reminders**: Local notifications for check-ins
4. **Export**: CSV/PDF export of historical data
5. **Achievements**: Streak tracking, badges
6. **Notes**: Add optional notes to events (triggers, mood)

### Performance Optimization:
1. Use predicates to limit query scope
2. Implement pagination for large datasets
3. Background context for bulk operations
4. Cache computed values (weekly averages, etc.)

## File Checklist

Make sure you have all these files in your project:

```
NailGuard/
├── NailGuardApp.swift          ✓ Entry point with PersistenceController
├── DashboardView.swift         ✓ Real-time dashboard with @Query
├── TrendsView.swift            ✓ Analytics with calendar view
├── SettingsView.swift          ✓ Settings and data management
├── PersistenceController.swift ✓ Centralized data layer
└── BiteEvent.swift             ✓ SwiftData model

Watch Extension/
├── WatchApp.swift              → Entry point
├── WatchHomeView.swift         → Main interface
├── WatchSyncManager.swift      → Sends events to phone
└── WatchStorage.swift          → Offline queue

Shared/
├── Models/
│   └── BiteEvent.swift         → Shared model
└── Sync/
    └── PhoneSyncManager.swift  → Receives from watch
```

---

**Last Updated**: February 2026  
**Architecture Version**: 1.0  
**SwiftData Version**: iOS 17+
