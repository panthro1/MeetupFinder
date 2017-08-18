//
//  Event.swift
//  MeetupFinder
//
//  Created by Roman Sheydvasser on 7/21/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Event {
    let id: String
    let name: String
    let description: String
    let groupName: String
    let rsvpCount: Int
    let rsvpLimit: Int
    let longitude: Double
    let latitude: Double
    let time: Double
    let link: String
    
    init(id: String, name: String, description: String, groupName: String, rsvpCount: Int, rsvpLimit: Int, lat: Double, lon: Double, time: Double, link: String) {
        self.id = id
        self.name = name
        self.description = description
        self.groupName = groupName
        self.rsvpCount = rsvpCount
        self.rsvpLimit = rsvpLimit
        self.latitude = lat
        self.longitude = lon
        self.time = time
        self.link = link
    }
    
    init() {
        self.id = ""
        self.name = ""
        self.description = ""
        self.groupName = ""
        self.rsvpCount = 0
        self.rsvpLimit = 0
        self.latitude = 0
        self.longitude = 0
        self.time = 0
        self.link = ""
    }
    
    func toAnyObject() -> Any {
        return [
            "id" : id,
            "name" : name,
            "description" : description,
            "groupName" : groupName,
            "rsvpCount" : rsvpCount,
            "rsvpLimit" : rsvpLimit,
            "latitude" : latitude,
            "longitude" : longitude,
            "time" : time,
            "link" : link
        ]
    }
}
