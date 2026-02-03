//
//  BiteEvent.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/3/26.
//
import Foundation

struct BiteEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
}
