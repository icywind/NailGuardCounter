//
//  BiteEventModel.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/3/26.
//

import SwiftData
import Foundation
import SwiftUI

@Model
final class BiteEventModel {
    @Attribute(.unique) var id: UUID
    var timestamp: Date

    init(id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
    }
}
