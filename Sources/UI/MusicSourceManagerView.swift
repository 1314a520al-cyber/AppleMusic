//
//  MusicSourceManagerView.swift
//  AppleMusic
//
//  音源管理。
//
//  交互：
//    1. 粘贴音源地址或 JSON，自动识别是否需要卡密；
//    2. 识别不了会明确提示「无法识别」；
//    3. 识别成功且需要卡密时自动弹出卡密输入框；
//    4. 支持从文件导入（.json / .txt / .js）；
//    5. 每个音源可单独测试，结果直接显示「可以用」或「不可以用」。
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
    @State private var testResults: [String: TestOutcome] = [:]
    @State private var inputError: String?
    @State private var importMessage: String?

    enum TestOutcome: Equatable {
        case ok
        case fail

        var text: String {
            switch self {
            case .ok:   return "可以用"
            case .fail: return "不可以用"
            }
        }

        var color: Color {
            switch self {
            case .ok:   return .green
            case .fail: return .red
            }
        }

        var icon: String {
            switch self {
            case .ok:   return "checkmark.circle.fill"
            case .fail: return "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        CompatNavigationStack {
            ZStack {
                BackdropLayer()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        addCard
                        listCard
                    }
                    .padding(16)
                }
                .compatScrollIndicatorsHidden()
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
            allowedContentTypes: [.json, .plainText, .text, .data],
            allowsMultipleSelection: false
        ) { handleFileImport($0) }
    }

    private var addCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("添加音源")
                .font(.system(size: 17, weight: .semibold))

            Text("粘贴音源地址或配置（支持 URL 或 JSON），会自动识别是否需要卡密。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $inputText)
                .font(.system(size: 13, design: .monospaced))
                .frame(minHeight: 104)
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.6)
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if let inputError {
                hintRow(icon: "exclamationmark.triangle.fill", tint: .orange, text: inputError)
            }
            if let importMessage {
                hintRow(icon: "doc.badge.plus", tint: .blue, text: importMessage)
            }

            HStack(spacing: 10) {
                Button { Haptics.tap(); addFromInput() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 15))
                        Text("添加").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Capsule().fill(AppSettings.shared.accent.color))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button { Haptics.tap(); showFileImporter = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus").font(.system(size: 15))
                        Text("上传文件").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(16)
        .background { card }
    }

    private func hintRow(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(tint)
            Text(text)
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("已添加音源").font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("\(store.sources.count) 个").font(.system(size: 14)).foregroundStyle(.secondary)
            }

            if store.sources.isEmpty {
                Text("还没有音源，粘贴一个地址或 JSON，或点「上传文件」导入。")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.sources) { source in
                        sourceCard(source)
                        if source.id != store.sources.last?.id { InsetDivider(leading: 16) }
                    }
                }
                .background { card }
            }
        }
    }

    private func sourceCard(_ source: MusicSource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 15))
                    .foregroundStyle(source.isUsable ? AppSettings.shared.accent.color : Color.secondary)
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
                .tint(AppSettings.shared.accent.color)
                .scaleEffect(0.85)
            }

            HStack(spacing: 12) {
                if source.requiresKey { keyBadge(source) }

                if let outcome = testResults[source.id] {
                    HStack(spacing: 4) {
                        Image(systemName: outcome.icon).font(.system(size: 11))
                        Text(outcome.text).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(outcome.color)
                }

                Spacer(minLength: 0)

                Button { Haptics.tap(); testSource(source) } label: {
                    HStack(spacing: 4) {
                        if testingID == source.id { ProgressView().scaleEffect(0.7) }
                        else { Image(systemName: "bolt.horizontal.circle").font(.system(size: 13)) }
                        Text(testingID == source.id ? "测试中" : "测试").font(.system(size: 13))
                    }
                    .foregroundStyle(AppSettings.shared.accent.color)
                }
                .buttonStyle(.plain)
                .disabled(testingID != nil || !source.isUsable)

                Button {
                    Haptics.tap()
                    store.remove(id: source.id)
                    testResults.removeValue(forKey: source.id)
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

    private var card: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.primary.opacity(0.05))
    }

    private func addFromInput() {
        inputError = nil
        importMessage = nil

        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let parsed = MusicSourceParser.parse(text) else {
            inputError = "无法识别。请粘贴一个以 http 开头的音源地址，或包含 url / template 字段的 JSON。"
            ToastCenter.shared.error("无法识别这个音源")
            Haptics.error()
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
        testResults.removeValue(forKey: source.id)

        Task {
            let sample = Song(id: 0, name: "晴天", artists: "周杰伦", album: "",
                              coverURL: nil, duration: 0)
            let result = await MusicSourceResolver.test(source: source, sample: sample)
            await MainActor.run {
                testingID = nil
                if result != nil {
                    testResults[source.id] = .ok
                    Haptics.success()
                } else {
                    testResults[source.id] = .fail
                    Haptics.error()
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            var data: Data?
            do {
                data = try Data(contentsOf: url)
            } catch {
                // 某些来源直接读会失败，改用文件协调器读取
                var coordinatorError: NSError?
                var readData: Data?
                NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinatorError) { newURL in
                    readData = try? Data(contentsOf: newURL)
                }
                data = readData
            }

            guard let data, !data.isEmpty else {
                inputError = "无法读取文件内容，请确认文件是 UTF-8 编码的 .json / .txt / .js"
                ToastCenter.shared.error("读取文件失败")
                return
            }

            guard let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .utf16) else {
                inputError = "文件编码无法识别，请使用 UTF-8 编码"
                ToastCenter.shared.error("文件编码不支持")
                return
            }

            inputText = text
            importMessage = "已读取「\(url.lastPathComponent)」（\(text.count) 字符），正在识别…"
            addFromInput()

        case .failure(let error):
            inputError = "选择文件失败：\(error.localizedDescription)"
            ToastCenter.shared.error("选择文件失败")
        }
    }
}
