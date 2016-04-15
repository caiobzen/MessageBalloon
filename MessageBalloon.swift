//
//  MessageBalloon.swift
//  message balloon
//
//  Created by Carlos Corrêa on 13/04/16.
//  Copyright © 2016 Carlos Corrêa. All rights reserved.
//

import Foundation
import UIKit

// MARK: Helpers

extension CGPath {
    //scaling :http://www.google.com/url?q=http%3A%2F%2Fstackoverflow.com%2Fquestions%2F15643626%2Fscale-cgpath-to-fit-uiview&sa=D&sntz=1&usg=AFQjCNGKPDZfy0-_lkrj3IfWrTGp96QIFQ
    //nice answer from David Rönnqvist!
    class func rescaleForFrame(path: CGPath, frame: CGRect) -> CGPath {
        let boundingBox = CGPathGetBoundingBox(path)
        let boundingBoxAspectRatio = CGRectGetWidth(boundingBox)/CGRectGetHeight(boundingBox)
        let viewAspectRatio = CGRectGetWidth(frame)/CGRectGetHeight(frame)
        
        var scaleFactor: CGFloat = 1.0;
        if (boundingBoxAspectRatio > viewAspectRatio) {
            scaleFactor = CGRectGetWidth(frame)/CGRectGetWidth(boundingBox)
        } else {
            scaleFactor = CGRectGetHeight(frame)/CGRectGetHeight(boundingBox)
        }
        
        var scaleTransform = CGAffineTransformIdentity
        scaleTransform = CGAffineTransformScale(scaleTransform, scaleFactor, scaleFactor)
        scaleTransform = CGAffineTransformTranslate(scaleTransform, -CGRectGetMinX(boundingBox), -CGRectGetMinY(boundingBox))
        let scaledSize = CGSizeApplyAffineTransform(boundingBox.size, CGAffineTransformMakeScale(scaleFactor, scaleFactor))
        let centerOffset = CGSizeMake((CGRectGetWidth(frame)-scaledSize.width)/(scaleFactor*2.0), (CGRectGetHeight(frame)-scaledSize.height)/(scaleFactor*2.0))
        scaleTransform = CGAffineTransformTranslate(scaleTransform, centerOffset.width, centerOffset.height)
        if let resultPath = CGPathCreateCopyByTransformingPath(path, &scaleTransform) {
            return resultPath
        }
        
        return path
    }
}


enum AnimationKeyPath:String {
    case
    scale        = "transform.scale",
    yPosition    = "position.y",
    opacity      = "opacity"
}

// MARK: Dots

class Dots: UIView {
    
    private var caLayer: CALayer = CALayer()
    var dotColor = UIColor.blackColor() {
        didSet {
            caLayer.backgroundColor = dotColor.CGColor
        }
    }
    
    private var replicator: CAReplicatorLayer {
        get {
            return layer as! CAReplicatorLayer
        }
    }
    
    override class func layerClass() -> AnyClass {
        return CAReplicatorLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Replicator
        replicator.backgroundColor = UIColor.clearColor().CGColor
        replicator.instanceCount = 3
        replicator.instanceTransform = CATransform3DMakeTranslation(dotSize() * 1.6, 0.0, 0.0)
        replicator.instanceDelay = 0.1
        
        //Layer
        caLayer = CALayer()
        caLayer.bounds = CGRect(x: 0.0, y: 0.0, width: dotSize(), height: dotSize())
        caLayer.position = CGPoint(x: center.x - (dotSize() * 1.6), y: center.y + (dotSize() * 0.2))
        caLayer.cornerRadius = dotSize() / 2
        caLayer.backgroundColor = dotColor.CGColor
        
        replicator.addSublayer(caLayer)
        
        animationStart()
    }
    
    func dotSize() -> CGFloat {
        return self.frame.size.height / 10
    }
    
    // Animations
    
    func createAnimation(keyPath:AnimationKeyPath, fromValue:CGFloat, toValue:CGFloat, duration:CFTimeInterval) -> CASpringAnimation{
        let animation = CASpringAnimation(keyPath: keyPath.rawValue)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards;
        return animation
    }
    
    func animationGroup(duration:CFTimeInterval, name:String, animations:[CASpringAnimation]) -> CAAnimationGroup {
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = animations
        animationGroup.duration = duration
        animationGroup.setValue(name, forKey: "animation")
        animationGroup.delegate = self
        animationGroup.removedOnCompletion = false
        animationGroup.fillMode = kCAFillModeForwards;
        return animationGroup
    }
    
    func animationStart() {
        let move = createAnimation(.yPosition, fromValue:caLayer.position.y, toValue: caLayer.position.y - dotSize(), duration: 0.5)
        let alpha = createAnimation(.opacity, fromValue: 1.0, toValue: 0.0, duration: 0.5)
        let scale = createAnimation(.scale, fromValue: 1.0, toValue: 1.3, duration: 0.5)
        let anim = animationGroup(0.5, name: "up", animations: [move, alpha, scale])
        caLayer.addAnimation(anim, forKey: nil)
    }
    
    func animationEnd() {
        let move = createAnimation(.yPosition, fromValue:caLayer.position.y + 5, toValue:caLayer.position.y, duration:0.2)
        let alpha = createAnimation(.opacity, fromValue: 0.0, toValue: 1.0, duration: 0.5)
        let scale = createAnimation(.scale, fromValue: 0.5, toValue: 1.0, duration: 0.3)
        let anim = animationGroup(0.7, name: "down", animations: [move, alpha, scale])
        caLayer.addAnimation(anim, forKey: nil)
    }

    // Animation Delegate
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if (anim.valueForKey("animation") as! String == "up") {
            animationEnd()
        } else if (anim.valueForKey("animation") as! String == "down") {
            animationStart()
        }
    }
}

// MARK: Balloon

@IBDesignable
class MessageBalloon: UIView {

    @IBInspectable var lineWidth:CGFloat = 5
    @IBInspectable var color: UIColor = UIColor.clearColor()
    @IBInspectable var lineColor:UIColor = UIColor.blackColor()
    @IBInspectable var dotColor:UIColor = UIColor.blackColor() {
        didSet {
            dots.dotColor = dotColor
        }
    }
    
    var dots = Dots()

    var bezierPath = UIBezierPath()
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    private func shapeLayer() -> CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = UIColor.clearColor()
        
        //Balloon shape
        bezierPath.moveToPoint(CGPointMake(127.63, 28.23))
        bezierPath.addCurveToPoint(CGPointMake(127.63, 72.77), controlPoint1: CGPointMake(140.12, 40.53), controlPoint2: CGPointMake(140.12, 60.47))
        bezierPath.addCurveToPoint(CGPointMake(87.79, 77.06), controlPoint1: CGPointMake(116.81, 83.42), controlPoint2: CGPointMake(100.17, 84.85))
        bezierPath.addCurveToPoint(CGPointMake(74, 81), controlPoint1: CGPointMake(86.02, 77.56), controlPoint2: CGPointMake(74, 81))
        bezierPath.addCurveToPoint(CGPointMake(78.78, 68.57), controlPoint1: CGPointMake(74, 81), controlPoint2: CGPointMake(77.82, 71.07))
        bezierPath.addCurveToPoint(CGPointMake(73.17, 47.25), controlPoint1: CGPointMake(74.27, 62.24), controlPoint2: CGPointMake(72.4, 54.63))
        bezierPath.addCurveToPoint(CGPointMake(82.37, 28.23), controlPoint1: CGPointMake(73.9, 40.3), controlPoint2: CGPointMake(76.97, 33.55))
        bezierPath.addCurveToPoint(CGPointMake(127.63, 28.23), controlPoint1: CGPointMake(94.87, 15.92), controlPoint2: CGPointMake(115.13, 15.92))
        
        //Balloon configuration
        shapeLayer().path = CGPath.rescaleForFrame(bezierPath.CGPath, frame: frame)
        shapeLayer().strokeColor = lineColor.CGColor
        shapeLayer().fillColor = color.CGColor
        shapeLayer().lineJoin = kCALineJoinRound
        shapeLayer().lineWidth = lineWidth
        
        //Adding the dots
        dots = Dots(frame: bounds)
        dots.dotColor = dotColor
        
        addSubview(dots)
    }
}