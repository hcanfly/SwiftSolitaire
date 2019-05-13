//
//  CardStack.swift
//  CardStacks
//
//  Created by Gary on 4/22/19.
//  Copyright © 2019 Gary Hanson. All rights reserved.
//

import Foundation



protocol CardStackDelegate : AnyObject {
    func refresh()
}

// CardDataStacks have the card info for each card in the stack.
// CardStackView's subviews are CardViews based on these cards
class CardDataStack {
    weak var delegate: CardStackDelegate?
    
    var cards = [Card]()
    
    func addCard(card: Card) {
        cards.append(card)
        delegate?.refresh()
    }
    
    func canAccept(droppedCard: Card) -> Bool {
        return false
    }
    
    func topCard() -> Card? {
        return cards.last
    }
    
    func removeAllCards() {
        self.cards.removeAll()
        delegate?.refresh()
    }
    
    func popCards(numberToPop: Int, makeNewTopCardFaceup: Bool) {
        guard cards.count >= numberToPop else {
            assert(false, "Attempted to pop more cards than are on the stack!")
            return
        }
        
        cards.removeLast(numberToPop)
        
        if makeNewTopCardFaceup {
            var card = self.topCard()
            if card != nil {
                cards.removeLast()
                card!.faceUp = true
                cards.append(card!)
            }
        }
        delegate?.refresh()
    }
    
    var isEmpty: Bool {
        return cards.isEmpty
    }
    
}

final class TableauStack : CardDataStack {
    
    override func canAccept(droppedCard: Card) -> Bool {
        
        if let topCard = self.topCard() {
            let (_, topCardRank) = topCard.getCardSuitAndRank()
            let (_, droppedCardRank) = droppedCard.getCardSuitAndRank()
            if topCard.faceUp && !topCard.cardSuitIsSameColor(card: droppedCard) && (droppedCardRank == topCardRank - 1) {
                return true
            }
        } else {
            // if pile is empty accept any King
            if droppedCard.isKing {
                return true
            }
        }
        
        return false
    }
}

final class FoundationStack : CardDataStack {
    
    override func canAccept(droppedCard: Card) -> Bool {
        if cards.isEmpty {
            return droppedCard.isAce      // if pile is empty, take any Ace
        }
        
        if let topCard = self.topCard() {
            let (topSuit, topRank) = topCard.getCardSuitAndRank()
            let (droppedSuit, droppedRank) = droppedCard.getCardSuitAndRank()
            if topSuit == droppedSuit && droppedRank == topRank + 1  {
                return true
            }
        }
        
        return false
    }
}

final class TalonStack : CardDataStack {
    
    override func canAccept(droppedCard: Card) -> Bool {
        // can't drop anything here
        return false
    }
}

final class StockStack : CardDataStack {
    
    override func canAccept(droppedCard: Card) -> Bool {
        // can't drop anything here
        return false
    }
}

final class DragStack : CardDataStack {
    
}
