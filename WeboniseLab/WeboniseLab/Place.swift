//
//  Place.swift
//  WeboniseLab
//
//  Created by Netstratum on 2/18/17.
//  Copyright © 2017 irfan. All rights reserved.
//

import UIKit

struct location {
    var latitude = 0.0, longitude = 0.0
}

class Place: NSObject {
    var pId : String!
    var pName : String!
    var pVicinity : String!
    var pLocation = location()
    var pIcon : String?
    var pPhotos : [[String:Any]]?
    var iconData : Data?
}
