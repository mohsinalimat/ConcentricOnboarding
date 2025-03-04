//
//  ContentView.swift
//  ConcentricOnboarding
//
//  Created by Alisa Mylnikova on 30/07/2019.
//  Copyright © 2019 Exyte. All rights reserved.
//

import SwiftUI

public struct ConcentricOnboardingView : View {
    public var animationWillBegin = {}
    public var animationDidEnd = {}
    public var didGoToLastPage = {}
    public var currentPageIndex: Int {
        return currentIndex
    }

    let radius: Double = 30
    let limit: Double = 15

    static let timerStep = 0.02
    let timer = Timer.publish(every: timerStep, on: .current, in: .common).autoconnect()
    var step: Double {
        2*limit / (duration / ConcentricOnboardingView.timerStep)
    }

    let pages: [AnyView]
    let bgColors: [Color]
    let duration: Double // in seconds

    @State var currentIndex = 0
    @State var nextIndex = 1

    @State var progress: Double = 0
    @State var isAnimating = false {
        didSet {
            if isAnimating && (pages.count < 2 || bgColors.count < 2) {
                isAnimating = false
                return
            }
            isAnimating ? animationWillBegin() : animationDidEnd()
        }
    }
    @State var isAnimatingForward = true
    @State var bgColor = Color.white
    @State var circleColor = Color.white

    @State var shape = AnyView(Circle())

    public init(pages: [AnyView], bgColors: [Color], duration: Double = 1.0) {
        self.pages = pages
        self.bgColors = bgColors
        self.duration = duration
    }

    func viewWillAppear() {
        if bgColors.count != pages.count {
            print("Pages count should be the same as bg colors")
        }
        if pages.count < 2 {
            print("Add more pages")
        }
        if bgColors.count < 2 {
            print("Add more bg colors")
        }

        if bgColors.count > currentIndex {
            bgColor = bgColors[currentIndex]
        }
        if bgColors.count > nextIndex {
            circleColor = bgColors[nextIndex]
        }
        let width = CGFloat(radius * 2)
        shape = AnyView(Circle().foregroundColor(circleColor).frame(width: width, height: width, alignment: .center))
    }

    public var body: some View {

        let mainView = ZStack {
            bgColor

            ZStack {
                Button(action: {
                    self.isAnimating = true
                }) { shape }

                if !isAnimating {
                    Image("arrow")
                        .resizable()
                        .frame(width: 7, height: 12)
                        .foregroundColor(bgColor)
                }
            }
            .offset(y: 300)

            currentPages()
                .offset(y: -50)
        }
        .edgesIgnoringSafeArea(.vertical)
        .onReceive(timer) { _ in
            if !self.isAnimating {
                return
            }
            self.isAnimatingForward ? self.refreshAnimatingViewsForward() : self.refreshAnimatingViewsBackward()
        }

        return mainView
            .onAppear() {
                self.viewWillAppear()
            }
    }

    func createGrowingShape(_ progress: Double) -> AnyView {
        let r = CGFloat(radius + pow(2, progress))
        let d = r*2
        let delta = CGFloat((1 - progress/limit) * radius)
        if progress > 10 {
        return AnyView(Path { b in
            b.addArc(center: CGPoint(x: UIScreen.main.bounds.width/2 + r + CGFloat(radius) - delta, y: UIScreen.main.bounds.height/2), radius: r, startAngle: Angle(radians: -.pi/2), endAngle: Angle(radians: .pi/2), clockwise: true)
            }.foregroundColor(circleColor))
        } else {
            return AnyView(Circle().foregroundColor(circleColor).position(x: d-delta, y: r).frame(width: d, height: d))
        }
    }

    func createShrinkingShape(_ progress: Double) -> AnyView {
        let r = CGFloat(radius + pow(2, (limit - progress)))
        let d = r*2
        let delta = CGFloat(progress/limit * radius)
        if progress < limit - 10 {
            return AnyView(Path { b in
                b.addArc(center: CGPoint(x: UIScreen.main.bounds.width/2 - r + CGFloat(radius) + delta, y: UIScreen.main.bounds.height/2), radius: r, startAngle: Angle(radians: -.pi/2), endAngle: Angle(radians: .pi/2), clockwise: false)
            }.foregroundColor(circleColor))
        } else {
            return AnyView(Circle().foregroundColor(circleColor).position(x: delta, y: r).frame(width: d, height: d))
        }
    }
    
    func refreshAnimatingViewsForward() {
        progress += step
        if progress < limit {
            bgColor = bgColors[currentIndex]
            circleColor = bgColors[nextIndex]
            shape = createGrowingShape(progress)
        }
        else if progress < 2*limit {
            bgColor = bgColors[nextIndex]
            circleColor = bgColors[currentIndex]
            shape = createShrinkingShape(progress - limit)
        }
        else {
            isAnimating = false
            progress = 0
            goToNextPageUnanimated()
        }
    }

    func refreshAnimatingViewsBackward() {
        progress += step
        let backwardProgress = 2*limit - progress
        if progress < limit {
            bgColor = bgColors[currentIndex]
            circleColor = bgColors[nextIndex]
            shape = createShrinkingShape(backwardProgress - limit)
        }
        else if progress < 2*limit {
            bgColor = bgColors[nextIndex]
            circleColor = bgColors[currentIndex]
            shape = createGrowingShape(backwardProgress)
        }
        else {
            isAnimating = false
            progress = 0
            goToPrevPageUnanimated()
        }
    }

    func currentPages() -> some View {
        let maxXOffset = 600.0
        let maxYOffset = 40.0
        let currentPageOffset = easingOutProgressFor(time: progress/limit/2)
        let nextPageOffset = easingInProgressFor(time: 1 - progress/limit/2)
        let coeff: CGFloat = isAnimatingForward ? -1 : 1

        var reverseScaleFactor = 1 - nextPageOffset/3
        if reverseScaleFactor == 0 {
            reverseScaleFactor = 1
        }

        return ZStack {
            if pages.count > 0 { pages[currentIndex]
                //swap effects order to create another animation
                .scaleEffect(CGFloat(1 - currentPageOffset/3))
                .offset(x: coeff * CGFloat(maxXOffset * currentPageOffset),
                        y: CGFloat(maxYOffset * currentPageOffset))
            }

            if pages.count > 1 { pages[nextIndex]
                .scaleEffect(CGFloat(reverseScaleFactor))
                .offset(x: -coeff * CGFloat(maxXOffset * nextPageOffset),
                        y: CGFloat(maxYOffset * nextPageOffset))
            }
        }
    }

    func updateColors() {
        let width = CGFloat(radius * 2)
        shape = AnyView(Circle().foregroundColor(circleColor).frame(width: width, height: width, alignment: .center))

        bgColor = bgColors[currentIndex]
        circleColor = bgColors[nextIndex]
    }

    func goToNextPageAnimated() {
        isAnimatingForward = true
        nextIndex = moveIndexForward(currentIndex)
        isAnimating = true
    }

    func goToNextPageUnanimated() {
        isAnimatingForward = true
        currentIndex = moveIndexForward(currentIndex)
        nextIndex = moveIndexForward(currentIndex)
        updateColors()
    }

    func goToPrevPageAnimated() {
        isAnimatingForward = false
        nextIndex = moveIndexBackward(currentIndex)
        isAnimating = true
    }

    func goToPrevPageUnanimated() {
        isAnimatingForward = false
        currentIndex = moveIndexBackward(currentIndex)
        nextIndex = moveIndexBackward(currentIndex)
        updateColors()
    }

    public func goToNextPage(animated: Bool = true) {
        animated ? goToNextPageAnimated() : goToNextPageUnanimated()
    }

    public func goToPreviousPage(animated: Bool = true) {
        animated ? goToPrevPageAnimated() : goToPrevPageUnanimated()
    }

    // helpers

    func easingInProgressFor(time t: Double) -> Double {
        return t * t
    }

    func easingOutProgressFor(time t: Double) -> Double {
        return -(t * (t - 2))
    }

    func moveIndexForward(_ index: Int) -> Int {
        if index + 1 < pages.count {
            return index + 1
        } else {
            return 0
        }
    }

    func moveIndexBackward(_ index: Int) -> Int {
        if index - 1 >= 0 {
            return index - 1
        } else {
            return pages.count - 1
        }
    }
}

