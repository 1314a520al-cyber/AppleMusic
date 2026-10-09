//
//  RewardView.swift
//  AppleMusic
//
//  赞赏支持页：展示赞赏二维码图片。
//  图片放在 Assets.xcassets/RewardQR.imageset（仓库 md 里只保留这一张）。
//

import SwiftUI

struct RewardView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.red)
                            Text("赞赏支持")
                                .font(.system(size: 24, weight: .bold))
                            Text("如果这个 App 对你有帮助，可以请我喝杯咖啡 ☕️")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)

                        // 赞赏码图片
                        rewardImage
                            .frame(width: 260, height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
                            }
                            .shadow(color: .black.opacity(0.10), radius: 16, y: 6)

                        Text("长按图片可保存")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("赞赏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var rewardImage: some View {
        if let uiImage = UIImage(named: "RewardQR") {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ZStack {
                LinearGradient(colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(.secondary)
                    Text("赞赏码未配置")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
