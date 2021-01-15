//
//  Feed.swift
//  CheckIn
//
//  Created by Deniz Adil on 15.1.21.
//

import UIKit
import Foundation

struct Feed: Codable {
    var id: String?
    var imageUrl: String?
    var creatorId: String?
    var createdAt: TimeInterval?
    var location: String?
}
