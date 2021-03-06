//
//  MeetupClient.swift
//  MeetupFinder
//
//  Created by Roman Sheydvasser on 7/18/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreLocation
import Firebase

class MeetupClient: NSObject {
    
    static let shared = MeetupClient()
    
    var allEvents: [Event] = []
    var openEvents: [Event] = []
    var currentLocation = CLLocation(latitude: 0, longitude: 0)
    
    let cachedEventsRef = Database.database().reference(withPath: "cachedEvents")
    let eventsRef = Database.database().reference(withPath: "events")
    
    func getValueFromUrlParameter(url: String, parameter: String) -> String? {
        let queryItems = URLComponents(string: url)?.queryItems
        let param1 = queryItems?.filter({$0.name == parameter}).first
        return param1?.value
    }
    
    func buildUrl(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> String {
        let url = "\(Constants.baseUrl)\(Constants.findEventsMethod)?key=\(Constants.apiKey)&sign=true&photo-host=public&lon=\(longitude)&radius=smart&fields=group_category,group_photo,featured_photo&lat=\(latitude)"
        return url
    }
    
    func makeEvent(json: JSON) -> Event? {
        if let id = json["id"].string,
            let name = json["name"].string,
            let groupName = json["group"]["name"].string,
            let category = json["group"]["category"]["name"].string,
            let time = json["time"].double,
            let link = json["link"].string
        {
            let event = Event(id: id, name: name, groupName: groupName, category: category, time: time, link: link)
            
            if let rsvpCount = json["yes_rsvp_count"].int,
                let rsvpLimit = json["rsvp_limit"].int {
                event.rsvpCount = rsvpCount
                event.rsvpLimit = rsvpLimit
            }
            if let lat = json["venue"]["lat"].double,
                let lon = json["venue"]["lon"].double {
                event.latitude = lat
                event.longitude = lon
            }
            if let groupPhotoUrl = json["group"]["photo"]["photo_link"].string {
                event.groupPhotoUrl = groupPhotoUrl
            }
            if let description = json["description"].string {
                event.description = description
            }
            
            return event
            
        } else {
            //print("INVALID EVENT FROM JSON")
            return nil
        }
    }
    
    func makeEventFromFirebase(_ dict: [String:Any?]) -> Event? {
        if let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let groupName = dict["groupName"] as? String,
            let category = dict["category"] as? String,
            let time = dict["time"] as? Double,
            let link = dict["link"] as? String
        {
            let event = Event(id: id, name: name, groupName: groupName, category: category, time: time, link: link)
            
            if let rsvpCount = dict["rsvpCount"] as? Int,
                let rsvpLimit = dict["rsvpLimit"] as? Int {
                event.rsvpCount = rsvpCount
                event.rsvpLimit = rsvpLimit
            }
            
            if let lat = dict["latitude"] as? Double,
                let lon = dict["longitude"] as? Double {
                event.latitude = lat
                event.longitude = lon
            }
            if let groupPhotoUrl = dict["groupPhotoUrl"] as? String {
                event.groupPhotoUrl = groupPhotoUrl
            }
            if let description = dict["description"] as? String {
                event.description = description
            }
            
            return event
            
        } else {
            print("INVALID EVENT FROM FIREBASE")
            return nil
        }
    }
    
    func getMeetups(lat: CLLocationDegrees, long: CLLocationDegrees, onComplete: @escaping ()->Void) {
        guard let cacheId = self.convertLocationToId(Double(lat), Double(long)) else {
            print("Could not generate cache ID from coordinate.")
            return
        }
        
        checkForCachedEvents(cacheId) { cacheExists in
            if cacheExists {
                self.downloadCachedEvents(cacheId) { onComplete() }
            } else {
                Alamofire.request(self.buildUrl(latitude: lat, longitude: long)).responseJSON {
                    response in
                    if let jsonRaw = response.result.value,
                        let eventJsonArray = JSON(jsonRaw).array {
                        self.allEvents.removeAll()
                        self.openEvents.removeAll()
                    
                        for eventJson in eventJsonArray {
                            if let event = self.makeEvent(json: eventJson) {
                                self.saveEventToFirebase(event)
                                self.allEvents.append(event)
                                if event.rsvpLimit != event.rsvpCount, event.latitude != 0 {
                                    self.openEvents.append(event)
                                }
                            } else {
                                print("INVALID JSON")
                            }
                        }
                        self.cacheEventsToFirebase(cacheId, self.allEvents)
                    }
                    onComplete()
                }
            }
        }
    }
    
    func downloadImage(url: String, completionHandler: @escaping (_ success: Bool, _ data: Data?) -> Void) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask)[0]
            documentsURL.appendPathComponent("image")
            return (documentsURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(url, to: destination).responseData { response in
            print(response)
            if let error = response.result.error {
                Helper.displayAlert(error.localizedDescription)
                completionHandler(false, nil)
            }
            if let data = response.result.value {
                print("Data received.")
                completionHandler(true, data)
            }
        }
    }
}
