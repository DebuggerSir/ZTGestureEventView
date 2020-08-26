//
//  ZTGestureEventView.swift
//  FBSnapshotTestCase
//
//  Created by Skyer God on 2020/8/26.
//

import UIKit

open class ZTGestureEventView: UIView {
    /// 避免手指开屏幕后抖动造成的影响
    private let offsetPix:CGFloat = 0
    private (set) var direction:PanDirecrion = .none
    private (set) var panDirection:PanDirecrion = .none {
        didSet {
            if panDirection != oldValue{
                oldMovePoint = movePoint
            }
        }
    }
    //MARK: - 计算touch事件的偏移量，方向等，勿动
    private (set) var absolutionOffset:CGPoint = .zero
    private (set) var oldMovePoint:CGPoint = .zero
    private let thresholdValue:CGFloat = 10
    private var startPoint: CGPoint = .zero
    private var movePoint: CGPoint = .zero
    private var endPoint: CGPoint = .zero
    private var panPoint:CGPoint = .zero {
        didSet {
            if direction == .left || direction == .right {
                if panPoint.x < oldValue.x - offsetPix {
                    panDirection = .left
                } else if panPoint.x > oldValue.x + offsetPix{
                    panDirection = .right
                }
            } else if direction == .up || direction == .down {
                if panPoint.y < oldValue.y - offsetPix{
                    panDirection = .up
                } else if panPoint.y > oldValue.y + offsetPix{
                    panDirection = .down
                }
            }
        }
    }
    
    /// state：枚举值- 触摸的状态
    /// direction：滑动方向
    /// pointMeta：state对应的point值
    /// panPoint：拖动位移
    /// complete：是否拖动结束
    var touchesActions:((_ state:TouchStatus, _ direction:PanDirecrion, _ pointMeta:(begin:CGPoint, move:CGPoint, end:CGPoint, panPoint:CGPoint), _ complete:Bool)->())? = nil
    var touchesSingleTapAction:((_ touchePoint:CGPoint)->())? = nil
    var touchesContinueTapAction:((_ touchePoint:CGPoint)->())? = nil
    
    private var task:GCDTask? = nil
    /// feed视频定制的单击事件，可以区分单次点击和连续连击
    var singleTapGesture: SingleTapGesture = SingleTapGesture()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 自定义单击手势和连续点击手势
    internal func singleTapAction(timeStamp: TimeInterval, status: TouchStatus) {
        switch status {
        case .begin:
            singleTapGesture.beginTouchTimeStamp = timeStamp
        case .end:
            let tap = self.singleTapGesture
            if let beginTimeStamp = tap.beginTouchTimeStamp, rounding(value: startPoint.x) == rounding(value:endPoint.x), rounding(value: startPoint.y) == rounding(value: endPoint.y) {
                let sub = timeStamp - beginTimeStamp
                let tapDuraction =  beginTimeStamp - (tap.latestTimeStamp ?? beginTimeStamp)
                /// 单点手势
                if sub >= tap.minTapDuration, sub <= tap.maxTapDuration {
                    /// 区分连续单点 和 单次单点
                    if tapDuraction < tap.continuousClickDuration, tapDuraction != 0 {
                        //执行连击显示爱心的方法
                        self.touchesContinueTapAction?(self.startPoint)
                        //取消执行单击方法
                        self.cancelTask(self.task)
//                        print("_++__连续\((tapDuraction, sub))")
                    } else {
//                        print("_++__单点\((tapDuraction, sub))")
                        //推迟0.3秒执行单击方法
                        self.task = delayTask(tap.singleTapDelayTime) {[weak self] in
                            guard let `self` = self else {return}
                            self.touchesSingleTapAction?(self.startPoint)
                        }
                    }
                }
                singleTapGesture.update(time: timeStamp)
            }
        default:
            break
        }
    }
    
    internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first
        let point = touch?.location(in: self)
        guard let startPoint = point else {return}
        //记录开始点击位置
        self.startPoint = startPoint
        self.direction = .none
        self.panDirection = .none
        self.panPoint = .zero
        self.endPoint = .zero
        
        absolutionOffset = .zero
        oldMovePoint = .zero
        panPoint = .zero
        touchesActions?(.begin, direction, (self.startPoint, self.movePoint, self.endPoint, panPoint), false)
        
        /// 处理业务
        let timeStamp = touch?.timestamp ?? 0
//        print("+++begin\(timeStamp)")
        singleTapAction(timeStamp: timeStamp, status: .begin)
    }
    
    internal override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let touch = touches.first
        let point = touch?.location(in: self)
        guard let endPoint = point else {return}
        self.endPoint = endPoint
        touchesActions?(.end, direction, (self.startPoint, self.movePoint, self.endPoint, panPoint), true)
        
        /// 处理业务
        let timeStamp = touch?.timestamp ?? 0
//        print("+++end\(timeStamp)")
        singleTapAction(timeStamp: timeStamp, status: .end)
    }
    
    internal override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        let touch = touches.first
        let point = touch?.location(in: self)
        
        guard let movePoint = point else {return}
        self.movePoint = movePoint
        //计算滑动的距离
        panPoint = CGPoint(x: movePoint.x - startPoint.x, y: movePoint.y - startPoint.y)
        if direction == .none {
            if panPoint.x <= -thresholdValue {
                direction = .left
            } else if panPoint.x >= thresholdValue {
                direction = .right
            } else if panPoint.y <= -thresholdValue {
                direction = .up
            } else if panPoint.y >= thresholdValue {
                direction = .down
            }
        }
//        if direction == .none { return }
        
        
        absolutionOffset = CGPoint(x: movePoint.x - oldMovePoint.x, y: movePoint.y - oldMovePoint.y)
        touchesActions?(.move, direction, (self.startPoint, self.movePoint, self.endPoint, panPoint), false)
        
        /// 处理业务
        let timeStamp = touch?.timestamp ?? 0
//        print("+++move\(timeStamp)")
        singleTapAction(timeStamp: timeStamp, status: .move)
    }
    
    internal override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        let touch = touches.first
        let point = touch?.location(in: self)
        
        guard let cancelPoint = point else {return}
        //计算滑动的距离
        
        panPoint = CGPoint(x: cancelPoint.x - startPoint.x, y: cancelPoint.y - startPoint.y)
        absolutionOffset = CGPoint(x: cancelPoint.x - oldMovePoint.x, y: cancelPoint.y - oldMovePoint.y)
        touchesActions?(.cancel, direction, (self.startPoint, self.movePoint, self.endPoint, panPoint), true)
        
        /// 处理业务
        let timeStamp = touch?.timestamp ?? 0
//        print("+++cancel\(timeStamp)")
        singleTapAction(timeStamp: timeStamp, status: .cancel)
    }
    
    //如果发现添加后，所在控制器不走这里的ToucheDelegate方法，则实现此方法
    //    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    //        return false
    //    }
}

//如果此view全屏且所属控制器需要侧滑返回，或底s上滑返回，则需要在 所在控制器实现UIGestureDelegate的以下代理方法
//func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//    let point = touch.location(in: gestureRecognizer.view)
//    if CGRect(x: 20, y: 0, width: Constants.SCREEN_WIDTH - 20, height: Constants.SCREEN_HEIGHT - 20).contains(point) {
//        return false
//    }
//    return true
//}



extension ZTGestureEventView {
    typealias GCDTask = (_ cancel: Bool) -> Void
    
    /// block延迟可取消任务
    ///
    /// - Parameters:
    ///   - time: 延迟时间
    ///   - task: 任务
    /// - Returns: 任务
    func delayTask(_ time: TimeInterval, task: @escaping () -> ()) -> GCDTask? {
        
        func dispatch_later(block: @escaping () -> ()) {
            let t = DispatchTime.now() + time
            DispatchQueue.main.asyncAfter(deadline: t, execute: block)
        }
        
        var closure: (() -> Void)? = task
        var result: GCDTask?
        
        let delayedClosure: GCDTask = { cancel in
            
            if let internalClosure = closure {
                if (cancel == false) {
                    DispatchQueue.main.async(execute: internalClosure)
                }
            }
            closure = nil
            result = nil
        }
        
        result = delayedClosure
        dispatch_later {
            if let delayedClosure = result {
                delayedClosure(false)
            }
        }
        
        return result
    }
    
    /// 取消任务
    ///
    /// - Parameter task: 将要取消的任务
    func cancelTask(_ task: GCDTask?) {
        task?(true)
    }
}

//MARK - 自定义业务
extension ZTGestureEventView {
    
    enum PanDirecrion:Int {
        case left = 0
        case right
        case down
        case up
        case none
    }
    enum TouchStatus:Int {
        case begin = 0
        case move
        case end
        case cancel
        case none
    }
    /// 自定义单点手势
    struct SingleTapGesture {
        var beginTouchTimeStamp: TimeInterval?
        var minTapDuration: TimeInterval = 0.0
        var maxTapDuration: TimeInterval = 0.1
        /// 默认不处理连续点击事件,需要时可自己设置时长
        var continuousClickDuration: TimeInterval = 0
        /// 当设置连续连击事件后, 需要设置延迟时间 用于取消冲突的单点事件
        var singleTapDelayTime:TimeInterval = 0
        private(set) var latestTimeStamp: TimeInterval?
        
        mutating func update(time toucheEndOrCancel: TimeInterval) {
            self.latestTimeStamp = toucheEndOrCancel
            beginTouchTimeStamp = nil
        }
    }
}

extension ZTGestureEventView {
    // 保留N位小数.如果为XX.0 则返回XX
    // 例子: 11.11保留1位 = 11.1   11.01保留1位 = 11    11.001保留2位 = 11
    private func rounding(value: CGFloat) -> Int {
        let num: Int = 0
        // 根据所取位数，化分为整
        let intValue = Int(Float(value) * powf(10, Float(num)))
        // 取整数部分
        let intPart =  intValue / Int(powf(10, Float(num)))
        return intPart
    }
}
