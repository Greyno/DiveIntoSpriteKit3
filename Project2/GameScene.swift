//
//  GameScene.swift
//  DiveIntoSpriteKit
//
//  Created by Paul Hudson on 16/10/2017.
//  Copyright © 2017 Paul Hudson. All rights reserved.
//

import GameplayKit
import SpriteKit

@objcMembers
class GameScene: SKScene {
    
    var level = 1 //Track the difficulty levl of the game
    var startTime = 0.0
    var timeLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
    var isGameRunning = true
    
    let music = SKAudioNode(fileNamed: "night-cave")
    let scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
    //Create a property observer for the score
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        // this method is called when your game scene is ready to run
        
        let background = SKSpriteNode(imageNamed: "background-pattern")
        background.zPosition = -1
        background.name = "background"
        addChild(background)
        
        scoreLabel.position = CGPoint(x: -480, y: 330)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = 1
        score = 0
        
        timeLabel.position = CGPoint(x:480, y: 330)
        timeLabel.horizontalAlignmentMode = .right
        timeLabel.zPosition = 1
        
        //Add the score label, time label and music as children of the background node, not as children of the root gamescene
        background.addChild(scoreLabel)
        background.addChild(music)
        background.addChild(timeLabel)
        createGrid()
        createLevel()
    }
    
    //MARK: Game Play
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user touches the screen
        guard isGameRunning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location) //returns [SKNode]
        guard let tapped = tappedNodes.first else { return }
        if tapped.name == "correct" {
            correctAnswer(node: tapped)
        } else { wrongAnswer(node: tapped)}
        
    }
    
    func correctAnswer(node: SKNode) {
        isUserInteractionEnabled = false
        score += 1
        run(SKAction.playSoundFileNamed("correct-3", waitForCompletion: false))
        //When the correct ball is chosen, fade out the incorrect balls
        let fade = SKAction.fadeOut(withDuration: 0.5) //Create and configure the action

        for child in children {
            guard child.name == "wrong" else {continue}
            child.run(fade) //Execute the action on the nodes of interest
        }
        
        //Dynamically change the size of the correct answer ball
        //Remove to test
        let scaleUp = SKAction.scale(to: 2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        node.run(sequence)
        
        //Level up after a 0.5 second wait after the fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.level += 1
            self.createLevel()
        }
        
    }
    
    func wrongAnswer(node: SKNode) {
        score -= 1
        run(SKAction.playSoundFileNamed("wrong-3", waitForCompletion: false))
        let wrong = SKSpriteNode(imageNamed: "wrong")
        let locationForX = node.position
        wrong.position = locationForX
        wrong.zPosition = 5
        addChild(wrong)
    
        //Move the player down one level
        //Level up after a 0.5 second wait after the fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.level -= 1
            if self.level == 0 {
                self.level = 1
            }
            self.createLevel()
            wrong.removeFromParent() //This prevents having a larger ball left behind on reshuffle
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // this method is called when the user stops touching the screen
    }
    
    override func update(_ currentTime: TimeInterval) {
        // this method is called before each frame is rendered
        
        //If the game is running, show the time label, otherwise do not show the label
        if isGameRunning {
            if startTime == 0 {
                startTime = currentTime
            }
            let timePassed = currentTime - startTime
            let remainingTime = Int(ceil(10 - timePassed))
            
            if remainingTime <= 5 {
                timeLabel.color = UIColor.red
            }
            
            timeLabel.text = "TIME: \(remainingTime)"
            timeLabel.alpha = 1
            
            //Start a new game when time runs out
            if remainingTime <= 0 {
                isGameRunning = false
                
                let gameOver = SKSpriteNode(imageNamed:"gameOver1")
                gameOver.zPosition = 100
                addChild(gameOver)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    //Create a new scene from GameScence.sks
                    if let scene = GameScene(fileNamed: "GameScene") {
                        //make it stretch to fill all available space
                        scene.scaleMode = .aspectFill
                        //present it immediately
                        self.view?.presentScene(scene)
                    }
                })
            }
        } else {
            timeLabel.alpha = 0
        }
    }
    
    //MARK: Helper Methods
    func createGrid() {
        //Create a grid of balls that is 12 wide by 8 high
        
        let yOffset = -275 //was -320
        let xOffset = -425 //was -440
        for row in 0 ..< 8 {
            for col in 0 ..< 12 {
                let item = SKSpriteNode(imageNamed: "1")
                item.position = CGPoint(x: xOffset + (col * 80), y: yOffset + (row * 80))
                addChild(item)
            }
        }
    }
    
    func createLevel(){
        //Whenever a new level starts, reset the timer clock
        startTime = 0
        
        //Show 4 more balls for every level of difficulty (max is 96 balls or level 24)
        var numberOfBallsToShow = level * 4
        numberOfBallsToShow = min(numberOfBallsToShow, 96)
        
        isUserInteractionEnabled = true
        let shuffledBalls = generateShuffledBalls()
        generateGuessingGrid(shuffledBalls: shuffledBalls, ballsPerLevel: numberOfBallsToShow)
    }
    
    fileprivate func generateGuessingGrid(shuffledBalls: [SKSpriteNode], ballsPerLevel: Int) {
        //Determine the highest number to show
        let highest = GKRandomSource.sharedRandom().nextInt(upperBound: 11) + 5
        var others = [Int]()
        
        //Generate lots of numbers lower than that
        for _ in 1 ..< ballsPerLevel {
            let num = GKRandomSource.sharedRandom().nextInt(upperBound: highest)
            others.append(num)
        }
        
        for (index, number) in others.enumerated() {
            //Pull out one of the random balls
            
            //Give it the correct texture for its new number
            let item = shuffledBalls[index]
            item.texture = SKTexture(imageNamed: String(number))
            
            //Make it visible but marked as wrong
            item.alpha = 1
            item.name = "wrong"
        }
        
        //Show one of the balls as being the correct ball
        shuffledBalls.last?.texture = SKTexture(imageNamed: String(highest))
        shuffledBalls.last?.alpha = 1
        shuffledBalls.last?.name = "correct"
    }
    
    fileprivate func generateShuffledBalls() -> [SKSpriteNode] {
        
        //Shuffle the items in the grid
        
        //Get all the children in the SKNode, except for the background
        let balls = children[1...children.count-1] //Returns an ArraySlice<SKNode>
        //[1..<]
        let ballArray = Array(balls) //Convert the ArraySlice to an [SKNode]
        let shuffledBalls = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: ballArray) as! [SKSpriteNode]
        
        //Change the opacity/visibility of the balls to "invisible" (0.0)
        for item in shuffledBalls {
            item.alpha = 0.0
        }
        return shuffledBalls
    }

}

