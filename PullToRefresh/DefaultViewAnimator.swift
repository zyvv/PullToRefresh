//
//  DefaultViewAnimator.swift
//  PullToRefreshDemo
//
//  Created by Serhii Butenko on 26/7/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

private extension CGFloat {
    var rads: CGFloat { return self * CGFloat.pi / 180 }
}

class ArcLayer: CAShapeLayer {
    
    var value: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var lineColor: UIColor!
    
    private let startAngle = CGFloat(0).rads
    private var toEndAngle: CGFloat {
        return (value * 360.0).rads + startAngle
    }
    
    override func draw(in context: CGContext) {
        super.draw(in: context)
        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }
        drawArc(in: context)
    }
    
    private func drawArc(in ctx: CGContext) {
        let arcLineWidth: CGFloat = 1.5
        let center: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = (min(bounds.width, bounds.height) - arcLineWidth)/2 * 0.5
        let arcPath: UIBezierPath = UIBezierPath(arcCenter: center,
                                                   radius: radius,
                                                   startAngle: startAngle,
                                                   endAngle: toEndAngle,
                                                   clockwise: true)
        ctx.setLineWidth(arcLineWidth)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(lineColor.cgColor)
        ctx.addPath(arcPath.cgPath)
        ctx.drawPath(using: .stroke)
    }
}

class RefreshView: UIView {
    
    private var arcLayer: ArcLayer!
    
    init(lineColor: UIColor) {
        super.init(frame: .zero)
        setup(lineColor: lineColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(lineColor: UIColor) {
        arcLayer = ArcLayer()
        arcLayer.lineColor = lineColor
        arcLayer.contentsScale = UIScreen.main.scale
        arcLayer.shouldRasterize = true
        arcLayer.rasterizationScale = UIScreen.main.scale * 2
        arcLayer.masksToBounds = false
        backgroundColor = UIColor.clear
        arcLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(arcLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let arcLayerWidth = min(frame.height, frame.width)
        arcLayer.frame = CGRect(x: (frame.width - arcLayerWidth)/2.0,
                                y: (frame.height - arcLayerWidth)/2.0,
                                width: arcLayerWidth,
                                height: arcLayerWidth)
    }

    func releasingAnimation(progress: CGFloat) {
        arcLayer.value = max(0, progress-0.2)
        if progress > 0.8 {
            let deltaProgress = (progress - 0.8) / 0.2
            arcLayer.opacity = Float(0.5 + 0.5 * deltaProgress)
        }
    }
    
    func loadingAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = CGFloat(360).rads
        rotation.repeatCount = Float.greatestFiniteMagnitude
        rotation.duration = 0.7
        arcLayer.add(rotation, forKey: "rotationAnimation")
    }
    
    func finishedAnimation() {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.fromValue = 1.0
        flash.toValue = 0
        flash.duration = 0.1
        arcLayer.add(flash, forKey: "flashAnimation")
    }
    
    func initialSetup() {
        arcLayer.removeAllAnimations()
        arcLayer.opacity = 0.5
        releasingAnimation(progress: 0)
    }
    
    func animate(_ state: State) {
        switch state {
        case .initial: initialSetup()
        case .releasing(let progress):
            releasingAnimation(progress: progress)
        case .loading:
            loadingAnimation()
        case .finished:
            finishedAnimation()
        }
    }
}

class DefaultViewAnimator: RefreshViewAnimator {
    
    fileprivate let refreshView: RefreshView
    
    init(refreshView: RefreshView) {
        self.refreshView = refreshView
    }
    
    func animate(_ state: State) {
        refreshView.animate(state)
    }
}
