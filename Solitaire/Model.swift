//
//  Model.swift
//  Solitaire
//
//  Created by Gary on 4/27/19.
//  Copyright © 2019 Gary Hanson. All rights reserved.
//

import UIKit

class Model {
    static let sharedInstance = Model()

    var deck = Array(0 ..< 52)
    var cards = [CardView]()  // persistent storage of cardViews

    var tableauStacks = [TableauStack]()
    var foundationStacks = [FoundationStack]()
    var talonStack = TalonStack()
    var stockStack = StockStack()
    var dragStack = DragStack()
    
    private init() {
        self.initialize()
    }
    
    func shuffle() {
        self.deck.shuffle()
    }
    
    private func initialize() {
        // frame is just a default placeholder. real frame is set in stack views
        // but need width and height to initalize subviews in cardview
        let frame = CGRect(x: 0, y: 0, width: CARD_WIDTH, height: CARD_HEIGHT)
        for index in deck {
            self.cards.append(CardView(frame: frame, value: self.deck[index]))
        }
        
        for _ in 0 ..< 4 {
            self.foundationStacks.append(FoundationStack())
        }
        
        for _ in 0 ..< 7 {
            self.tableauStacks.append(TableauStack())
        }
    }
}
