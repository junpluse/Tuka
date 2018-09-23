//
//  Message.swift
//  Touches
//
//  Created by Jun Tanaka on 2017/03/29.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

import Tuka
import CoreGraphics

struct TouchMessage: Tuka.Message {
    let location: CGPoint
    let radius: CGFloat
}
