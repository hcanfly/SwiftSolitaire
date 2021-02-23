//
//  SolitaireGameView.swift
//  CardStacks
//
//  Created by Gary on 4/22/19.
//  Copyright © 2019 Gary Hanson. All rights reserved.
//

import UIKit


fileprivate let SPACING = CGFloat(UIScreen.main.bounds.width > 750 ? 10.0 : 3.0)
let CARD_WIDTH = CGFloat((UIScreen.main.bounds.width - CGFloat(7.0 * SPACING)) / 7.0)
let CARD_HEIGHT = CARD_WIDTH * 1.42

private extension Selector {
    static let handleTap = #selector(SolitaireGameView.newDealAction)
}


final class SolitaireGameView: UIView {
    
    private var foundationStacks = [FoundationCardStackView]()
    private var tableauStackViews = [TableauStackView]()
    private var stockStackView = StockCardStackView(frame: CGRect.zero)
    private var talonStackView = TalonCardStackView()
    private var doingDrag = false           // flag to keep callbacks from trying to do stuff on touches when not dragging
    private var dragView = DragStackView(frame: CGRect.zero, cards: Model.sharedInstance.dragStack)   // view containing cards being dragged.
    private var stackDraggedFrom: CardStackView?
    private var dragPosition = CGPoint.zero
    private var baseTableauFrameRect = CGRect.init()

    //MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(hex: 0x004D2C)
        
        self.initStackViews()
        
        self.dealCards()
    }
    
    private func initStackViews() {
        let baseRect = CGRect(x: 4.0, y: scaled(value: 110.0), width: CARD_WIDTH, height: CARD_HEIGHT)
        var foundationRect = baseRect
        for index in 0 ..< 4 {
            let stackView = FoundationCardStackView(frame: foundationRect, cards: Model.sharedInstance.foundationStacks[index])
            self.addSubview(stackView)
            self.foundationStacks.append(stackView)
            foundationRect = foundationRect.offsetBy(dx: CGFloat(CARD_WIDTH + SPACING), dy: 0.0)
        }
        
        foundationRect = foundationRect.offsetBy(dx: CGFloat(CARD_WIDTH + SPACING), dy: 0.0)
        self.talonStackView = TalonCardStackView(frame: foundationRect, cards: Model.sharedInstance.talonStack)
        self.addSubview(self.talonStackView)
        
        foundationRect = foundationRect.offsetBy(dx: CGFloat(CARD_WIDTH + SPACING), dy: 0.0)
        self.stockStackView = StockCardStackView(frame: foundationRect, cards: Model.sharedInstance.stockStack)
        self.addSubview(self.stockStackView)
        
        var gameStackRect = baseRect.offsetBy(dx: 0.0, dy: CGFloat(CARD_HEIGHT + scaled(value: 12.0)))
        self.baseTableauFrameRect = gameStackRect
        for index in 0 ..< 7 {
            let stackView = TableauStackView(frame: gameStackRect, cards: Model.sharedInstance.tableauStacks[index])
            self.addSubview(stackView)
            self.tableauStackViews.append(stackView)
            gameStackRect = gameStackRect.offsetBy(dx: CGFloat(CARD_WIDTH + SPACING), dy: 0.0)
        }
        
        let buttonFrame = CGRect(x: 1.0, y: scaled(value: 60.0), width: scaled(value: 70.0), height: scaled(value: 30.0))
        let newDealButton = UIButton(frame: buttonFrame)
        newDealButton.setTitle("New Deal", for: .normal)
        newDealButton.setTitleColor(.white, for: .normal)
        newDealButton.titleLabel?.font = .systemFont(ofSize: scaled(value: 14.0))
        newDealButton.addTarget(self, action: .handleTap, for: .touchUpInside)
        self.addSubview(newDealButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Deal
    @objc func newDealAction() {
        self.dealCards()
    }
    
    private func dealCards() {
        Game.sharedInstance.initalizeDeal()
        
        var tableauFrame = self.baseTableauFrameRect
        var cardValuesIndex = 0
        for outerIndex in 0 ..< 7 {
            self.tableauStackViews[outerIndex].frame = tableauFrame
            for innerIndex in (0 ... outerIndex) {
                Model.sharedInstance.tableauStacks[outerIndex].addCard(card: Card(value: Model.sharedInstance.deck[cardValuesIndex], faceUp: outerIndex == innerIndex))
                cardValuesIndex += 1
            }
            tableauFrame = tableauFrame.offsetBy(dx: CGFloat(CARD_WIDTH + SPACING), dy: 0.0)
        }
        
        for _ in cardValuesIndex ..< 52 {
            Model.sharedInstance.stockStack.addCard(card: Card(value: Model.sharedInstance.deck[cardValuesIndex], faceUp: false))
            cardValuesIndex += 1
        }
    }
    
}

// MARK: Handle dragging
extension SolitaireGameView {
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        let touch = touches.first!
        let tapCount = touch.tapCount
        if tapCount > 1 {
            handleDoubleTap(inView: touch.view!)
            return
        }
        
        if let touchedView = touch.view {
            Model.sharedInstance.dragStack.removeAllCards()
            dragView.removeAllCardViews()
            let touchPoint = touch.location(in: self)
            // we want the first view (in reverse order) that is visible and contains the touch point
            // create a drag view with this view, and other cards above it in the hierarchy, if any
            // the cards are removed from the stack during the drag, and then copied to either a new
            // stack or back to the originating stack.
            for cardView in touchedView.subviews.reversed() {
                if let cardView = cardView as? CardView {
                    let t = touch.location(in: cardView)
                    if cardView.isFaceUp && cardView.point(inside: t, with: event) {
                        stackDraggedFrom = touchedView as? CardStackView
                        let dragCard = Card(value: cardView.cardValue, faceUp: true)
                        if  let index = stackDraggedFrom!.cards.cards.firstIndex(where: { $0.value == dragCard.value })  {
                            // card that was touched
                            doingDrag = true
                            dragView.frame = cardView.convert(cardView.bounds, to: self)
                            self.addSubview(dragView)
                            Model.sharedInstance.dragStack.addCard(card: dragCard)
                            
                            // add any cards above it
                            if index < stackDraggedFrom!.cards.cards.endIndex - 1 {
                                for i in index + 1 ... stackDraggedFrom!.cards.cards.endIndex - 1 {
                                    let card = stackDraggedFrom!.cards.cards[i]
                                    Model.sharedInstance.dragStack.addCard(card: card)
                                }
                            }
                            
                            // the cards are now in the drag view so remove them from the stack
                            for card in Model.sharedInstance.dragStack.cards {
                                let index = stackDraggedFrom!.cards.cards.firstIndex { $0.value == card.value }
                                stackDraggedFrom!.cards.cards.remove(at: index!)
                            }
                            
                            stackDraggedFrom?.refresh()
                            dragView.refresh()
                            dragPosition = touchPoint
                            break
                        }
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard doingDrag else {
            return
        }
        
        if let touch = touches.first {
            let currentPosition = touch.location(in: self)
            
            let oldLocation = dragPosition
            dragPosition = currentPosition
            
            moveDragView(offset: CGPoint(x: (currentPosition.x) - (oldLocation.x), y: (currentPosition.y) - (oldLocation.y)))
        }
    }
    
    private func moveDragView(offset: CGPoint) {
        dragView.center = CGPoint(x: dragView.center.x + offset.x, y: dragView.center.y + offset.y)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>,
                                   with event: UIEvent?) {
        guard doingDrag else {
            return
        }
        
        dragView.cards.cards.forEach{ card in stackDraggedFrom!.cards.addCard(card: card) }
        dragView.removeFromSuperview()
        dragView.removeAllCardViews()
        
        dragView.bounds = CGRect.zero
        doingDrag = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        if doingDrag {
            var done = false
            let dragFrame = dragView.convert(dragView.bounds, to: self)
            
            for view in tableauStackViews where view != stackDraggedFrom! {
                let viewFrame = view.convert(view.bounds, to: self)
                if viewFrame.intersects(dragFrame) {
                    // if a drop here is valid, move card and break out of loop
                    if view.cards.canAccept(droppedCard: dragView.cards.cards.first!) {
                        for card in Model.sharedInstance.dragStack.cards {
                            view.cards.addCard(card: card)
                            if let stack = stackDraggedFrom as? TableauStackView {
                                stack.flipTopCard()
                                stack.refresh()
                            }
                        }
                        view.refresh()
                        done = true
                        break
                    }
                }
            }
            
            if (!done && dragView.cards.cards.count == 1) {      // can only drag one card at a time to Foundation stack
                for view in foundationStacks where view != stackDraggedFrom! {
                    let viewFrame = view.convert(view.bounds, to: self)
                    if viewFrame.intersects(dragFrame) {
                        // if a drop here is valid, move card and break out of loop
                        if view.cards.canAccept(droppedCard: dragView.cards.cards.first!) {
                            let card = Model.sharedInstance.dragStack.cards.first!
                            view.cards.addCard(card: card)
                            if let stack = stackDraggedFrom as? TableauStackView {
                                stack.flipTopCard()
                                stack.refresh()
                            }
                        }
                        done = true
                        view.refresh()
                        break
                    }
                }
            }
            
            if !done {
                // card(s) could be dropped, so put them back
                dragView.cards.cards.forEach{ card in stackDraggedFrom!.cards.addCard(card: card) }
            }
            
            dragView.removeFromSuperview()
            dragView.removeAllCardViews()
            
            dragView.bounds = CGRect.zero
            doingDrag = false
        }
    }
}

// MARK: Double Tap
extension SolitaireGameView {
    
    // if a card in the talon stack or one of the tableau stacks is double-tapped,
    // see if it can be added to a foundation stack
    // if you copy / paste these two functions and replace Foundation with Tableau
    // you can try moving them to a tableau stack if it doesn't go into a foundation stack
    // or, you can just let the user do something for themself :-)
    func handleDoubleTap(inView: UIView) {
        if let talonStack = inView as? TalonCardStackView {
            if let card = talonStack.cards.topCard() {
                if self.addCardToFoundation(card: card) {
                    talonStack.cards.popCards(numberToPop: 1, makeNewTopCardFaceup: true)
                }
            }
        } else if let tableauStack = inView as? TableauStackView {
            if let card = tableauStack.cards.topCard() {
                if self.addCardToFoundation(card: card) {
                    tableauStack.cards.popCards(numberToPop: 1, makeNewTopCardFaceup: true)
                }
            }
        }
    }
    
    private func addCardToFoundation(card: Card) -> Bool {
        var addedCard = false
        
        for stack in self.foundationStacks {
            if stack.cards.canAccept(droppedCard: card) {
                stack.cards.addCard(card: card)
                addedCard = true
                break
            }
        }
        
        return addedCard
    }
}
