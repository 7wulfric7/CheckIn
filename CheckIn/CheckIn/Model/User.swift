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
    var createdAt: String?
    var location: String?
    
    init(id: String) {
        self.id = id
    }
}

struct Coordinate: Codable {
    var lon: Double?
    var lat: Double?
}

class City: Codable {

    var id: Int = 0
    var name: String = ""
    var country: String? = ""
    var coord: Coordinate?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case country
        case coord
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(Int.self, forKey: .id)
        country = try container.decode(String.self, forKey: .country)
        coord = try container.decodeIfPresent(Coordinate.self, forKey: .coord)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
        try container.encode(country, forKey: .country)
        try container.encode(coord, forKey: .coord)
    }
}
