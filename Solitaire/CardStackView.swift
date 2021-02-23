//
//  CardStackView.swift
//  CardStacks
//
//  Created by Gary on 4/22/19.
//  Copyright © 2019 Gary Hanson. All rights reserved.
//

import UIKit


class CardStackView: UIView, CardStackDelegate {
    var cards = CardDataStack()
    
    init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards              // view model for the cards in a stack
        self.cards.delegate = self      // when the model's cards change the StackView is notified to re-generate its subviews
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(hex: 0x004D2C)
        self.layer.cornerRadius = 7.0
        self.layer.borderWidth = 2.0
        self.layer.borderColor = UIColor.white.cgColor
    }
    
    fileprivate func addCard(card: Card) {
        fatalError("CardStackView:addCard has to be implemented in subclass")
    }
    
    func popCard() {
        self.cards.popCards(numberToPop: 1, makeNewTopCardFaceup: true)
    }
    
    func topCard() -> CardView? {
        return self.subviews.last as! CardView?
    }
    
    func flipTopCard() {
        var topCard = self.cards.cards.last
        if topCard != nil {
            topCard!.faceUp = true
            _ = self.cards.cards.popLast()
            self.cards.cards.append(topCard!)
        }
    }
    
    func removeAllCardViews() {
        _ = self.subviews.filter {$0 is CardView}.map { $0.removeFromSuperview() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        self.setNeedsDisplay()
    }
}


class LayeredStackView: CardStackView {
    let cardLayerOffset: CGFloat = 0.24
    
    override fileprivate func addCard(card: Card) {
        var cardFrame = self.bounds
        if self.subviews.count > 0 {
            let previousCard = self.subviews.last! as! CardView
            let previousCardFrame = previousCard.frame
            let offset = previousCard.isFaceUp ? (CARD_HEIGHT * cardLayerOffset) : (CARD_HEIGHT * 0.07)
            cardFrame = previousCardFrame.offsetBy(dx: 0.0, dy: offset)
            self.frame.size.height += offset
        }
        let cardView = Model.sharedInstance.cards[card.value]
        cardView.frame = cardFrame
        cardView.faceUp = card.faceUp
        
        self.addSubview(cardView)
    }
    
    override func refresh() {
        self.removeAllCardViews()
        
        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: CARD_WIDTH, height: CARD_HEIGHT)
        cards.cards.forEach { card in
            self.addCard(card: card)
        }
        
        self.setNeedsDisplay()
    }
}

// Tableau stacks are the layered stacks where there are initially face down cards and a face up card and you build from a King down
final class TableauStackView: LayeredStackView {
    
    override init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards
        self.cards.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DragStackView: LayeredStackView {
    
    override fileprivate func addCard(card: Card) {
        var cardFrame = self.bounds
        if self.subviews.count > 0 {
            let previousCard = self.subviews.last! as! CardView
            let previousCardFrame = previousCard.frame
            let offset = previousCard.isFaceUp ? (CARD_HEIGHT * cardLayerOffset) : (CARD_HEIGHT * 0.07)
            cardFrame = previousCardFrame.offsetBy(dx: 0.0, dy: offset)
            self.frame.size.height += offset
        }
        let cardView = Model.sharedInstance.cards[card.value]
        cardView.frame = cardFrame
        cardView.faceUp = card.faceUp
        
        self.addSubview(cardView)
    }
    
    override init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards
        self.cards.delegate = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PiledStackView: CardStackView {
    
    override fileprivate func addCard(card: Card) {
        let cardView = Model.sharedInstance.cards[card.value]

        cardView.frame = self.bounds
        cardView.faceUp = card.faceUp
        
        self.addSubview(cardView)
    }
    
    // when the model stack changes, rebuild from the new data
    override func refresh() {
        self.removeAllCardViews()
        
        cards.cards.forEach { card in
            self.addCard(card: card)
        }
        
        self.setNeedsDisplay()
    }
    
    override init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards
        self.cards.delegate = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Foundation stacks are the piles that contain the Ace + other cards it its suit
final class FoundationCardStackView: PiledStackView {
    
    override init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards
        self.cards.delegate = self
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    func commonInit() {
        let label = UILabel(frame: self.bounds)
        label.text = "𝖠" // "A"
        label.alpha = 0.50
        label.textColor = .white
        label.textAlignment = .center
        let screenheight = UIScreen.main.bounds.height
        label.font = UIFont(name: "TrebuchetMS", size: screenheight * (screenheight > 900 ? 0.12 : 0.07))
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class StockCardStackView: PiledStackView {

    override init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards
        self.cards.delegate = self
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.gestureRecognizers = [gesture]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    @objc func handleTap() -> Bool {
        if let _ = self.cards.topCard() {
            Game.sharedInstance.moveTopCard(from: Model.sharedInstance.stockStack, to: Model.sharedInstance.talonStack, faceUp: true, makeNewTopCardFaceup: false)
            return true
        } else {
            // copy back from talon view
            Game.sharedInstance.copyCards(from: Model.sharedInstance.talonStack, to: Model.sharedInstance.stockStack)
            Model.sharedInstance.talonStack.removeAllCards()
        }
    
        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TalonCardStackView: PiledStackView {
    
    override init(frame: CGRect, cards: CardDataStack) {
        super.init(frame: frame)
        
        self.cards = cards
        self.cards.delegate = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

