//
//  PlaybackClock.swift
//  AppleMusic
//
//  播放进度时钟：把高频时间回调收拢成低频状态更新。
//

import Foundation
import Combine

final class PlaybackClock: ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var duration: Double = 0

    func update(progress newProgress: Double? = nil, duration newDuration: Double? = nil) {
        let apply = {
            if let newProgress, abs(newProgress - self.progress) > 0.02 { self.progress = newProgress }
            if let newDuration, abs(newDuration - self.duration) > 0.01 { self.duration = newDuration }
        }
        if Thread.isMainThread { apply() } else { DispatchQueue.main.async(execute: apply) }
    }

    func forceUpdate(progress: Double) {
        let apply = { self.progress = progress }
        if Thread.isMainThread { apply() } else { DispatchQueue.main.async(execute: apply) }
    }
}
