# 英文與繁體中文版本的維護方式

兩個 public repo：

- [kf-toy：英文文件與主要演算法實作](https://github.com/r04522611/kf-toy)
- [kf-toy-mandarin：繁體中文文件](https://github.com/r04522611/kf-toy-mandarin)

兩邊預設分支都是 `codex/kf-cpp-toy`，共同起點為 commit `2dc5edb`。C++ 實作、測試、建置檔、設定、參考證據及 Python／shell 工具完全相同。語言差異只放在 `README*` 與 `docs/`。這是兩個獨立 repo，不會自動同步。

演算法以英文 repo 為主。數學或數值修正先在英文版完成，再把相同共用檔案更新同步至中文版。盡量將程式修正與翻譯分成不同 commit。中文版可將英文 repo 設為 `upstream`，fetch 後 cherry-pick 純程式更新；不要直接用整份英文版本覆蓋翻譯文件。

同步後，在中文版執行：

```bash
python3 tools/verify_editions.py --peer /home/pinghua/kf-toy
```

工具會比對 `README*` 與 `docs/` 之外所有版本控制檔案的集合及 SHA256，包含 source、tests、tools、vendor notices、configs 與歷史 reference。Git ignore 排除的 build／data／results／plan 不納入。若有缺檔或不同內容，工具回傳 nonzero 並列出檔案。這保證共用程式一致，不代表翻譯品質或跨平台數值逐 byte 一致。

兩邊共用同一個報告工具。沒有 `docs/report-locale.json` 時輸出英文；中文版提供只有文字的 JSON 語系檔，template keys 與英文預設相同。兩版使用相同 sealed matrix、hashes、RMSE、容差、exit-status 判定與96組數值。可用同一份完整矩陣產生兩種語言的報告來核對；兩個已知1mm差異仍必須讓 `--require-reference` 回傳失敗。語系不影響 estimator。

發布同步版本前：

1. 共用程式有變更時，執行一致性工具與 Docker 內8組 CTest。
2. 核對文件相對連結、公式與對應操作指令。
3. 分開呈現96組 deterministic 通過與78／80歷史嚴格容差通過。
4. 分別 push 並確認兩邊遠端 HEAD 與 public visibility。

來源 provenance 與原研究 hashes 保留原樣。歷史 commit 仍可看到先前中英混合的文件；英文 repo 目前版本的全部文字已整理為英文。兩邊都不發布本地忽略的 plan、原始 recordings 與完整實驗輸出。
