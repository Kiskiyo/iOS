//
//  GameScene.swift
//  Run run
//
//  Created by Francisco Gutierrez on 03/12/2019.
//  Copyright © 2019 Francisco Gutierrez. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private let hero = SKSpriteNode(imageNamed: "hero1")
    let heroMovePointsPerSecond: CGFloat = 480
    var velocity = CGPoint.zero
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let playableRect: CGRect
    var lastTouchLocation: CGPoint?
    var play = false
    var timer = Timer()

    
    let heroRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let heroAnimation: SKAction
    
   
    //Se reproduce un sonido al chocar con el enemigo, otro sonido al coger un premio y otro sonido al aparecer el enemido en patalla...
    let enemyActionSound = SKAction.playSoundFileNamed("TIE.wav", waitForCompletion: false)
    let allyRescueSound: SKAction = SKAction.playSoundFileNamed("R2.wav", waitForCompletion: false)
    let enemyCollisionSound = SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false)
    
    // Al chocar se hace invencible el personaje durante unos segundos...
    var invincible = false
    
    
    // Comienzas la partida con 5 vidas y con 0 premios...
    var lives = 5
    var rescueAllies = 0
    var gameOver = false
    
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200
    
    
    // Label de vidas y puntuación, y el tipo de letra...
    let livesLabel = SKLabelNode(fontNamed: "Helvetica")
    let allyLabel = SKLabelNode(fontNamed: "Helvetica")
    
    var cameraRect : CGRect {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16/9 
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight)/2
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        var textures: [SKTexture] = []
        for i in  1...3 {
            textures.append(SKTexture(imageNamed: "hero\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        
        heroAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func debugDrawPlatableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4
        addChild(shape)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position =
                CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            background.zPosition = -1
            addChild(background)
        }
        
        hero.position = CGPoint(x: 400, y: 400)
        
        
        hero.run(SKAction.repeatForever(heroAnimation))
        addChild(hero)
       
        //run(SKAction.repeatForever(
          //  SKAction.sequence([SKAction.run() { [weak self] in
            //    self?.spawnEnemy()
              //  },
                //               SKAction.wait(forDuration: 4)])))
        
        //run(SKAction.repeatForever(
          //  SKAction.sequence([SKAction.run() { [weak self] in
            //    self?.spawnAlly()
              // },
                //               SKAction.wait(forDuration: 1)])))
        
        
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        
        // Label de vidas...
        livesLabel.text = "Vidas: \(lives)"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(
            x: -playableRect.size.width/3 + CGFloat(30),
            y: -playableRect.size.height/380 + CGFloat(380))
        cameraNode.addChild(livesLabel)
        
        
        // Label de puntuación...
        allyLabel.text = "Score: \(rescueAllies)"
        allyLabel.fontColor = SKColor.black
        allyLabel.fontSize = 100
        allyLabel.zPosition = 150
        allyLabel.horizontalAlignmentMode = .right
        allyLabel.verticalAlignmentMode = .bottom
        allyLabel.position = CGPoint(
            x: playableRect.size.width/3 - CGFloat(30),
            y: -playableRect.size.height/380 + CGFloat(380))
        cameraNode.addChild(allyLabel)
        
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveHeroToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !gameOver{
            if !play{
                
                // Intervalo de tiempo con el que van saliendo en pantalla los premios y los enemigos...
                
                timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(GameScene.spawnEnemy), userInfo: nil, repeats: true)
                
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameScene.spawnAlly), userInfo: nil, repeats: true)
                
                play = true
            }
        }
        
       
        
        
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    
        }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime

        
        move(sprite: hero, velocity: velocity)
        rotate(sprite: hero, direction: velocity, rotateRadiansPerSec: heroRotateRadiansPerSec)
        
        boundsCheckHero()

        
        // Al llegar a 0 vidas, salta una segunda pantalla indicando que has perdido la partida...
        if lives <= 0 && !gameOver {
            gameOver = true
            timer.invalidate()
            play = false
            print("you lose!")
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        moveCamera()
        livesLabel.text = "Vidas: \(lives)"
        allyLabel.text = "Score: \(rescueAllies)"
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        
        let amountToMove = velocity * CGFloat(dt)
        // print ("Cantidad a mover: \ (amountToMove)")
        sprite.position += amountToMove
    }
    
    func moveHeroToward(location: CGPoint) {
        // 1 Calcula la dirección donde debe ir el héroe...
        let offset = location - hero.position
        // 2 Calcula la longitud...
        
        // 3 normaliza el vector de compensación al vector unitario...
        let direccion = offset.normalized()
        
        // 4 calcula la velocidad usando el vector unitario...
        velocity = direccion * heroMovePointsPerSecond
    }
    
    func boundsCheckHero() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        if hero.position.x <= bottomLeft.x {
            hero.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
        }
        if hero.position.x >= topRight.x {
            hero.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if hero.position.y <= bottomLeft.y {
            hero.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if hero.position.y >= topRight.y {
            hero.position.y = topRight.y
            velocity.y = -velocity.y
            
            // Verifica los límites del héroe...
            
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
        
    }
    
    //1.Aparece el enemigo
    //2.Posición en la que aparece el enemigo
    //3.Velocidad del enemigo.
    //4.Sonido al aparecer el enemigo.
    @objc func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        
        enemy.position = CGPoint(
            x: cameraRect.maxX + enemy.size.width/2,
            y: CGFloat.random(
                min: cameraRect.minY + enemy.size.height/2,
                max: cameraRect.maxY - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        
        let actionMove = SKAction.moveBy(x: -(size.width + enemy.size.width), y: 0, duration: 2.0)
        let group = SKAction.group([actionMove,enemyActionSound])
        let actionRemove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([group, actionRemove]))
        
    }
    
    // Aparecen los premios para recoger...
    @objc func spawnAlly() {
        
        let ally = SKSpriteNode(imageNamed: "ally")
        ally.name = "ally"
        
        ally.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX,
                              max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY,
                              max: cameraRect.maxY))
        ally.zPosition = 50
        ally.setScale(0)
        addChild(ally)
        
        let appear = SKAction.scale(to: 1, duration: 0.5)
        
        ally.zRotation = -π / 16
        let leftWiggle = SKAction.rotate(byAngle: π/8, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle,rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp,scaleDown, scaleUp,scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear,groupWait,disappear,removeFromParent]
        ally.run(SKAction.sequence(actions))
        
    }
    
    @objc func spawnGame(){
        
        run(SKAction.repeatForever(
                   SKAction.sequence([SKAction.run() { [weak self] in
                       self?.spawnEnemy()
                       },
                                      SKAction.wait(forDuration: 4)])))
               
               run(SKAction.repeatForever(
                   SKAction.sequence([SKAction.run() { [weak self] in
                       self?.spawnAlly()
                       },
                                      SKAction.wait(forDuration: 1)])))
               
        
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(GameScene.spawnGame), userInfo: nil, repeats: true)
        
        
    }
    
    // Se suma un punto cada vez que se coge un premio. Se reproduce el sonido al recoger un premio...
    func heroHit(ally: SKSpriteNode) {
        rescueAllies += 1
        ally.removeFromParent()
        run(allyRescueSound)
        
        
        
        // Al coger 15 premios se gana la partida, y te lanza a una segunda pantalla donde te indica la victoria con una imagen...
        if rescueAllies >= 15 && !gameOver {
            gameOver = true
            print("you win!")
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    @objc func heroHit(enemy: SKSpriteNode) {
        invincible = true
        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let setHidden = SKAction.run() { [weak self] in
            self?.hero.isHidden = false
            self?.invincible = false
        }
        
        // Se pierde una vida al colisionar con el enemigo y se reproduce un sonido...
        hero.run(SKAction.sequence([blinkAction, setHidden]))
        run(enemyCollisionSound)
        
        lives -= 1
    }
    
    func checkCollisions() {
        var hitAllies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "ally") { node, _ in
            let ally = node as!SKSpriteNode
            if ally.frame.intersects(self.hero.frame) {
                hitAllies.append(ally)
            }
        }
        
        for ally in hitAllies {
            heroHit(ally: ally)
        }
        
        if invincible { return }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node, _ in
            let enemy = node as!SKSpriteNode
            if enemy.frame.intersects(self.hero.frame) {
                hitEnemies.append(enemy)
            }
        }
        
        for enemy in hitEnemies {
            heroHit(enemy: enemy)
        }
    }
     
    // Las dos imagenes en movimiento que aparecen de fondo de pantalla del juego...
    func backgroundNode() -> SKSpriteNode {

        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position =
            CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity =
            CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width <
                self.cameraRect.origin.x {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
    }
}
