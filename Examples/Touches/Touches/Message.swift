//
//  Message.swift
//  Touches
//
//  Created by Jun Tanaka on 2017/03/29.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Tuka

final class TouchMessage: NSObject, NSCoding, Message {
    var location: CGPoint
    var radius: CGFloat

    init(location: CGPoint, radius: CGFloat) {
        self.location = location
        self.radius = radius
    }

    convenience init?(coder aDecoder: NSCoder) {
        let location = aDecoder.decodeCGPoint(forKey: "location")
        let radius = CGFloat(aDecoder.decodeFloat(forKey: "radius"))
        self.init(location: location, radius: radius)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(location, forKey: "location")
        aCoder.encode(Float(radius), forKey: "radius")
    }

    override var description: String {
        return "TouchMessage(location: {\(location.x), \(location.y)}, radius: \(radius))"
    }
}
