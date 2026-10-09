//
//  CacheManagerView.swift
//  AppleMusic
//
//  清除缓存页。
//

import SwiftUI

struct CacheManagerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var categories: [CacheCategory] = []
    @State private var totalText = "0 KB"
    @State private var isClearing = false

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(spacing: 6) {
                            Text(totalText).font(.system(size: 34, weight: .bold))
                            Text("可清理缓存").font(.system(size: 13)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        }

                        VStack(spacing: 0) {
                            ForEach(categories) { category in
                                categoryRow(category)
                                if category.id != categories.last?.id { InsetDivider(leading: 56) }
                            }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        }

                        Button {
                            clearAll()
                        } label: {
                            HStack(spacing: 8) {
                                if isClearing { ProgressView().scaleEffect(0.8) }
                                else { Image(systemName: "trash.fill").font(.system(size: 15)) }
                                Text(isClearing ? "清理中…" : "清除全部缓存")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red)
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(isClearing)

                        Text("「已下载歌曲」不会被清理，如需删除请到资料库 → 已下载中操作。")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("清除缓存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
        .onAppear { refresh() }
    }

    private func categoryRow(_ category: CacheCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 15)).foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(category.color))

            Text(category.name).font(.system(size: 15))

            Spacer(minLength: 0)

            Text(CacheManager.formatted(category.size))
                .font(.system(size: 14)).foregroundStyle(.secondary)

            if category.name != "已下载歌曲" {
                Button {
                    Haptics.tap()
                    CacheManager.clearCategory(category.name)
                    ToastCenter.shared.success("已清理\(category.name)")
                    refresh()
                } label: {
                    Text("清理").font(.system(size: 13)).foregroundStyle(Color.accentColor)
                        .padding(.leading, 6)
                }
                .buttonStyle(.plain)
                .disabled(category.size == 0)
                .opacity(category.size == 0 ? 0.4 : 1)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private func refresh() {
        categories = CacheManager.categories()
        totalText = CacheManager.formatted(CacheManager.totalSize())
    }

    private func clearAll() {
        isClearing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CacheManager.clearAll()
            Haptics.success()
            ToastCenter.shared.success("缓存已清空")
            refresh()
            isClearing = false
        }
    }
}
