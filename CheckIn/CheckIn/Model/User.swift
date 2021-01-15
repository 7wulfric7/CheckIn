//
//  User.swift
//  CheckIn
//
//  Created by Deniz Adil on 14.1.21.
//

import Foundation

struct User: Codable {
    var id: String?
    var name: String?
    var password: String?
    var image: String?
    var email: String?
    var time: String?
    var location: String?
    
    init(id: String) {
        self.id = id
    }
}
