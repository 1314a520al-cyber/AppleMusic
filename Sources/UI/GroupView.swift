//
//  GroupView.swift
//  AppleMusic
//
//  交流群页：QQ 群 / TG 群，点击自动跳转对应 App。
//

import SwiftUI

struct GroupView: View {
    @Environment(\.dismiss) private var dismiss

    private let qqGroupURL = "https://qun.qq.com/universal-share/share?ac=1&authKey=gK79P149V02wF2J8sVuEqs3PK73INLT62KGtb9vys46q0GY4t0SxTDyFqOVbjbuQ&busi_data=eyJncm91cENvZGUiOiI1MjE0NzMyMjIiLCJ0b2tlbiI6Ii9MelJDU1VrQ1BaeEZvOHRySUo4RjVlNWlnb1IySW9JZFBKTFFUaElMdGJQRlJ3eW"
    private let tgGroupURL = "https://t.me/Vxinol"

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.green)
                            Text("交流群")
                                .font(.system(size: 24, weight: .bold))
                            Text("欢迎加入群聊反馈问题、交流使用心得")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 6)

                        groupCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            tint: Color(red: 0.11, green: 0.72, blue: 0.93),
                            title: "QQ 群",
                            subtitle: "点击自动跳转 QQ 加入群聊",
                            urlString: qqGroupURL
                        )

                        groupCard(
                            icon: "paperplane.fill",
                            tint: Color(red: 0.16, green: 0.62, blue: 0.86),
                            title: "Telegram 群",
                            subtitle: "点击自动跳转 Telegram",
                            urlString: tgGroupURL
                        )

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("交流群")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func groupCard(icon: String, tint: Color, title: String, subtitle: String, urlString: String) -> some View {
        Button {
            Haptics.tap()
            openURL(urlString)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(tint))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
    }

    /// 打开链接；若 App 未安装则回退到浏览器
    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success, let web = URL(string: string) {
                UIApplication.shared.open(web, options: [:], completionHandler: nil)
            }
        }
    }
}
