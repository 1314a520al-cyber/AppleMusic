//
//  MusicSourceManagerView.swift
//  AppleMusic
//
//  音源管理：粘贴导入（自动识别卡密 → 自动弹卡密框）、开关、删除、测试。
//

import SwiftUI
import UniformTypeIdentifiers

struct MusicSourceManagerView: View {

    @ObservedObject private var store = MusicSourceStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var showKeyPrompt = false
    @State private var pendingSource: MusicSource?
    @State private var cardKeyInput = ""

    @State private var showFileImporter = false
    @State private var testingID: String?
    @State private var errorText: String?

    var body: some View {
        CompatNavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 添加区
                        VStack(alignment: .leading, spacing: 10) {
                            Text("添加音源").font(.system(size: 17, weight: .semibold))

                            Text("粘贴音源地址或配置（支持 URL 或 JSON），会自动识别是否需要卡密。")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            TextEditor(text: $inputText)
                                .font(.system(size: 13, design: .monospaced))
                                .frame(minHeight: 96)
                                .padding(8)
                                .background {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.6)
                                }
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if let errorText {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12)).foregroundStyle(.orange)
                                    Text(errorText)
                                        .font(.system(size: 12)).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            HStack(spacing: 10) {
                                Button {
                                    Haptics.tap(); addFromInput()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill").font(.system(size: 15))
                                        Text("添加").font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Capsule().fill(Color.accentColor))
                                }
                                .buttonStyle(PressableButtonStyle())
                                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button {
                                    Haptics.tap(); showFileImporter = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.badge.plus").font(.system(size: 15))
                                        Text("文件").font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        }

                        // 已添加
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("已添加音源").font(.system(size: 17, weight: .semibold))
                                Spacer()
                                Text("\(store.sources.count) 个")
                                    .font(.system(size: 14)).foregroundStyle(.secondary)
                            }

                            if store.sources.isEmpty {
                                Text("还没有音源，粘贴一个地址或 JSON 试试。")
                                    .font(.system(size: 13)).foregroundStyle(.secondary)
                                    .padding(.vertical, 10)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(store.sources) { source in
                                        sourceCard(source)
                                        if source.id != store.sources.last?.id { InsetDivider(leading: 16) }
                                    }
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("音源管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("完成") { dismiss() } }
            }
        }
        .alert("该音源需要卡密", isPresented: $showKeyPrompt) {
            TextField("请输入卡密", text: $cardKeyInput)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("取消", role: .cancel) { pendingSource = nil; cardKeyInput = "" }
            Button("保存") { savePendingSource() }
        } message: {
            Text("这个音源需要卡密才能解析播放地址，请填写后保存。")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json, .plainText, .text],
            allowsMultipleSelection: false
        ) { handleFileImport($0) }
    }

    private func sourceCard(_ source: MusicSource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 15))
                    .foregroundStyle(source.isUsable ? Color.accentColor : Color.secondary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.name).font(.system(size: 15, weight: .medium)).lineLimit(1)
                    Text(source.template)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }

                Spacer(minLength: 4)

                Toggle("", isOn: Binding(
                    get: { source.enabled },
                    set: { store.setEnabled(id: source.id, enabled: $0); Haptics.select() }
                ))
                .labelsHidden()
                .scaleEffect(0.85)
            }

            HStack(spacing: 12) {
                if source.requiresKey { keyBadge(source) }
                Spacer(minLength: 0)

                Button {
                    Haptics.tap(); testSource(source)
                } label: {
                    HStack(spacing: 4) {
                        if testingID == source.id { ProgressView().scaleEffect(0.7) }
                        else { Image(systemName: "bolt.horizontal.circle").font(.system(size: 13)) }
                        Text("测试").font(.system(size: 13))
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(testingID != nil || !source.isUsable)

                Button {
                    Haptics.tap()
                    store.remove(id: source.id)
                    ToastCenter.shared.show("已删除")
                } label: {
                    Text("删除").font(.system(size: 13)).foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }

    private func keyBadge(_ source: MusicSource) -> some View {
        Button {
            Haptics.tap()
            pendingSource = source
            cardKeyInput = source.cardKey
            showKeyPrompt = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: source.missingKey ? "key.slash" : "key.fill").font(.system(size: 11))
                Text(source.missingKey ? "未填卡密" : "已填卡密").font(.system(size: 12))
            }
            .foregroundStyle(source.missingKey ? Color.orange : Color.green)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background { Capsule().fill((source.missingKey ? Color.orange : Color.green).opacity(0.12)) }
        }
        .buttonStyle(.plain)
    }

    private func addFromInput() {
        errorText = nil
        guard let parsed = MusicSourceParser.parse(inputText) else {
            errorText = "无法识别。请粘贴一个以 http 开头的音源地址，或一段包含 url 字段的 JSON。"
            ToastCenter.shared.error("无法识别音源")
            return
        }

        if parsed.requiresKey {
            pendingSource = MusicSource(
                name: parsed.name, template: parsed.template, urlPath: parsed.urlPath,
                headers: parsed.headers, enabled: true, requiresKey: true, cardKey: ""
            )
            cardKeyInput = ""
            showKeyPrompt = true
        } else {
            store.add(parsed: parsed)
            inputText = ""
            Haptics.success()
            ToastCenter.shared.success("已添加音源「\(parsed.name)」")
        }
    }

    private func savePendingSource() {
        guard var source = pendingSource else { return }
        let key = cardKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if store.source(id: source.id) != nil {
            store.setCardKey(id: source.id, key: key)
            ToastCenter.shared.success("卡密已更新")
        } else {
            source.cardKey = key
            store.add(source)
            ToastCenter.shared.success(key.isEmpty ? "已添加（未填卡密）" : "已添加并保存卡密")
        }

        if !key.isEmpty { inputText = "" }
        pendingSource = nil
        cardKeyInput = ""
        Haptics.success()
    }

    private func testSource(_ source: MusicSource) {
        testingID = source.id
        Task {
            let sample = Song(id: 0, name: "晴天", artists: "周杰伦", album: "",
                              coverURL: nil, duration: 0)
            let result = await MusicSourceResolver.test(source: source, sample: sample)
            await MainActor.run {
                testingID = nil
                if result != nil { ToastCenter.shared.success("音源可用"); Haptics.success() }
                else { ToastCenter.shared.error("音源无响应或未返回地址"); Haptics.error() }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .utf8) else {
                ToastCenter.shared.error("无法读取文件")
                return
            }
            inputText = text
            addFromInput()
        case .failure:
            ToastCenter.shared.error("选择文件失败")
        }
    }
}
