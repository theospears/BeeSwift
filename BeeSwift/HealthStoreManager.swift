//
//  HealthStoreManager.swift
//  BeeSwift
//
//  Created by Andy Brett on 11/28/17.
//  Copyright © 2017 APB. All rights reserved.
//

import Foundation
import HealthKit
import OSLog

class HealthStoreManager :NSObject {
    static let sharedManager = HealthStoreManager()
    private let logger = Logger(subsystem: "com.beeminder.beeminder", category: "HealthStoreManager")

    private let healthStore = HKHealthStore()

    /// The Connection objects responsible for updating goals based on their healthkit metrics
    /// Dictionary key is the goal id, as this is stable across goal renames
    private var connections: [String: GoalHealthKitConnection] = [:]

    /// Request acess to HealthKit data for the supplied metric
    ///
    /// This function will throw an exception on a major failure. However, it will return silently if the user chooses
    /// not to grant read access to the specified goal - Apple does not permit apps to know if they have been
    /// granted read permission
    public func requestAuthorization(metric: HealthKitMetric) async throws {
        logger.notice("requestAuthorization for \(metric.databaseString, privacy: .public)")

        try await self.requestAuthorization(read: [metric.sampleType()])
    }

    /// Start listening for background updates to the supplied goal if we are not already doing so
    public func ensureUpdatesRegularly(goal: JSONGoal) async throws {
        try await self.ensureUpdatesRegularly(goals: [goal])
    }

    /// Ensure we have background update listeners for all of the supplied goals such that they
    /// will be updated any time the health data changes.
    ///
    /// It is safe to pass the same goal or set of goals to this function multiple times, this function
    /// will ensure duplicate observers are not installed.
    public func ensureUpdatesRegularly(goals: [JSONGoal]) async throws {
        logger.notice("setupHealthKitGoals for \(goals.count, privacy: .public) goals")

        let goalConnections = goals.compactMap { self.connectionFor(goal:$0) }

        var permissions = Set<HKObjectType>()
        for connection in goalConnections {
            permissions.insert(connection.hkPermissionType())
        }
        if permissions.count > 0 {
            try await self.requestAuthorization(read: permissions)
        }

        // TODO: Where do exceptions go?
        await withThrowingTaskGroup(of: Void.self) { group in
            for connection in goalConnections {
                group.addTask {
                    // TODO: This could do terrible things around repeated auth requests
                    try await connection.setupHealthKit()
                }
            }
        }
    }

    /// Install observers for any goals we currently have permission to read
    ///
    /// This function will never show a permissions dialog - instead it will not update for
    /// metrics where we do not have permission.
    public func silentlyInstallObservers(goals: [JSONGoal]) {
        logger.notice("registerObserverQueries")

        let goalConnections = goals.compactMap { self.connectionFor(goal:$0) }
        for connection in goalConnections {
            connection.registerObserverQuery()
        }
    }

    /// Immediately update the supplied goal based on HealthKit's data record
    ///
    /// Any existing beeminder records for the date range provided will be updated or deleted.
    public func updateWithRecentData(goal: JSONGoal, days: Int) async throws {
        logger.notice("syncHealthKitData")

        guard let connection = self.connectionFor(goal: goal) else {
            throw RuntimeError("Failed to find connection for goal")
        }
        try await connection.hkQueryForLast(days: days)
    }

    /// Gets or creates an appropriate connection object for the supplied goal
    private func connectionFor(goal: JSONGoal) -> GoalHealthKitConnection? {
        if (goal.healthKitMetric ?? "") == "" {
            // Goal does not have a metric. Make sure any connection is removed
            connections.removeValue(forKey: goal.id)
            return nil
        } else {
            if connections[goal.id] == nil {
                logger.notice("Creating connection for \(goal.slug, privacy: .public) (\(goal.id, privacy: .public)) to metric \(goal.healthKitMetric ?? "nil", privacy: .public)")

                guard let metric = HealthKitConfig.shared.metrics.first(where: { (metric) -> Bool in
                    metric.databaseString == goal.healthKitMetric
                }) else {
                    return nil
                }
                connections[goal.id] = metric.createConnection(healthStore: healthStore, goal: goal)
            }
            return connections[goal.id]
        }
    }

    private func requestAuthorization(read: Set<HKObjectType>) async throws {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.healthStore.requestAuthorization(toShare: nil, read: read) { success, error in
                if error != nil {
                    continuation.resume(throwing: error!)
                } else if success == false {
                    continuation.resume(throwing: RuntimeError("Error requesting HealthKit authorization"))
                } else {
                    continuation.resume()
                }
            }
        })
    }

}
