//
//  AppEvents.swift
//  AppleMusic
//
//  全局通知名（登录态变化等）。
//  QQMusicAuth / KugouMusicAuth 会 post 这些通知。
//

import Foundation

extension Notification.Name {
    static let beansQQLoginDidUpdate = Notification.Name("beans.qq.login.didUpdate")
    static let beansKugouLoginDidUpdate = Notification.Name("beans.kugou.login.didUpdate")
}
