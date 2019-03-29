//
//  RectView.swift
//  Annotations
//
//  Created by Vuong Dao on 3/28/19.
//

import Foundation
import Cocoa

protocol RectViewDelegate {
    func rectView(_ rectView: RectView, didUpdate model: RectModel, atIndex index: Int)
}

struct RectViewState {
    var model: RectModel
    var isSelected: Bool
}

protocol RectView: CanvasDrawable {
    var delegate: RectViewDelegate? { get set }
    var state: RectViewState { get set }
    var modelIndex: Int { get set }
    var layer: CAShapeLayer { get }
    var knobDict: [RectPoint: KnobView] { get }
}

extension RectView {
    var model: RectModel { return state.model }
    
    var knobs: [KnobView] {
        return RectPoint.allCases.map { knobAt(rectPoint: $0)}
    }
    
    var path: CGPath {
        get {
            return layer.path!
        }
        set {
            layer.path = newValue
            layer.bounds = newValue.boundingBox
            layer.frame = layer.bounds
        }
    }
    
    var isSelected: Bool {
        get { return state.isSelected }
        set { state.isSelected = newValue }
    }
    
    static func createPath(model: RectModel) -> CGPath {
        let length = model.origin.distanceTo(model.to)
        let rect = NSBezierPath.rect(
            from: CGPoint(x: model.origin.x, y: model.origin.y),
            to: model.to.cgPoint,
            tailWidth: 5,
            headWidth: 15,
            headLength: length >= 20 ? 20 : CGFloat(length)
        )
        
        return rect.cgPath
    }
    
    static func createLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.fillColor = NSColor.red.cgColor
        layer.strokeColor = NSColor.red.cgColor
        layer.lineWidth = 0
        
        return layer
    }
    
    func knobAt(point: PointModel) -> KnobView? {
        return knobs.first(where: { (knob) -> Bool in
            return knob.contains(point: point)
        })
    }
    
    func knobAt(rectPoint: RectPoint) -> KnobView {
        return knobDict[rectPoint]!
    }
    
    func contains(point: PointModel) -> Bool {
        return layer.path!.contains(point.cgPoint)
    }
    
    func addTo(canvas: CanvasView) {
        canvas.canvasLayer.addSublayer(layer)
    }
    
    func removeFrom(canvas: CanvasView) {
        layer.removeFromSuperlayer()
        knobs.forEach { $0.removeFrom(canvas: canvas) }
    }
    
    func dragged(from: PointModel, to: PointModel) {
        let delta = from.deltaTo(to)
        state.model = model.copyMoving(delta: delta)
    }
    
    func draggedKnob(_ knob: KnobView, from: PointModel, to: PointModel) {
        let rectPoint = (RectPoint.allCases.first { (rectPoint) -> Bool in
            return knobDict[rectPoint]! === knob
        })!
        let delta = from.deltaTo(to)
        state.model = model.copyMoving(rectPoint: rectPoint, delta: delta)
    }
    
    func render(state: RectViewState, oldState: RectViewState? = nil) {
        if state.model != oldState?.model {
            layer.shapePath = RectViewClass.createPath(model: state.model)
            
            for rectPoint in RectPoint.allCases {
                knobAt(rectPoint: rectPoint).state.model = state.model.valueFor(rectPoint: rectPoint)
            }
            
            delegate?.rectView(self, didUpdate: model, atIndex: modelIndex)
        }
        
        if state.isSelected != oldState?.isSelected {
            if state.isSelected {
                knobs.forEach { (knob) in
                    layer.addSublayer(knob.layer)
                }
            } else {
                knobs.forEach { (knob) in
                    knob.layer.removeFromSuperlayer()
                }
            }
        }
    }
}

class RectViewClass: RectView {
    
    var state: RectViewState {
        didSet {
            render(state: state, oldState: oldValue)
        }
    }
    
    var delegate: RectViewDelegate?
    
    var layer: CAShapeLayer
    var modelIndex: Int
    
    lazy var knobDict: [RectPoint: KnobView] = [
        .origin: KnobViewClass(model: model.origin),
        .to: KnobViewClass(model: model.to)
    ]
    
    init(state: RectViewState, modelIndex: Int) {
        self.state = state
        self.modelIndex = modelIndex
        layer = RectViewClass.createLayer()
        render(state: state)
    }
}