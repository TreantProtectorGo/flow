# 🎉 新增任務功能更新

## 更新內容

### ✅ 已完成的修改

1. **「新增任務」按鈕行為變更**
   - **之前：** 點擊後打開 AI 聊天介面
   - **現在：** 點擊後直接打開任務表單對話框
   - 圖示從 `auto_awesome` (✨) 改為 `add` (➕)

2. **AI 拆解功能保留**
   - 「讓 AI 幫你拆解大任務」卡片仍然存在
   - 點擊該卡片會打開 AI 聊天介面
   - 位於「待辦事項」區塊頂部

---

## 🎯 現在的使用流程

### 方法 1：直接新增任務（推薦）⚡
1. 點擊右下角 **「新增任務」按鈕** (➕ 圖示)
2. 填寫任務表單：
   - 任務標題
   - 任務描述（可選）
   - 番茄鐘數量
   - 優先級
3. 點擊「保存」
4. 任務立即出現在列表中
5. 查看終端機日誌：
   ```
   📝 [DB] 插入任務: [你的任務標題] (ID: xxxxx)
   ✅ [DB] 任務插入成功
   ```

### 方法 2：使用 AI 拆解大任務 🤖
1. 點擊「待辦事項」區塊下的 **「讓 AI 幫你拆解大任務」卡片**
2. 在 AI 聊天介面輸入你的任務需求
3. AI 會給出建議和拆解方案
4. （未來功能）AI 自動提取並創建任務

---

## 📋 測試清單

### 基本測試
- [ ] 點擊「新增任務」按鈕
- [ ] 任務表單對話框正確顯示
- [ ] 填寫所有欄位並保存
- [ ] 任務出現在「待辦事項」列表
- [ ] 終端機顯示 `📝 [DB] 插入任務` 訊息
- [ ] SnackBar 顯示「已新增任務：XXX」

### 表單驗證測試
- [ ] 必填欄位檢查（標題）
- [ ] 番茄鐘數量範圍檢查（1-8）
- [ ] 優先級選擇正常
- [ ] 取消按鈕正常運作

### AI 功能保留測試
- [ ] 「讓 AI 幫你拆解大任務」卡片正常顯示
- [ ] 點擊卡片打開 AI 聊天介面
- [ ] AI 聊天功能正常

### 資料庫測試
- [ ] 新增的任務正確保存到 SQLite
- [ ] 重啟應用後任務仍然存在
- [ ] 終端機日誌正確輸出

---

## 🔄 與之前的差異

### 之前的流程（已改變）：
```
點擊「新增任務」 → AI 聊天介面 → 手動從 AI 建議創建任務
```

### 現在的流程（更快速）：
```
方法 1：點擊「新增任務」 → 任務表單 → 立即創建 ✅
方法 2：點擊 AI 卡片 → AI 聊天 → （未來）自動提取任務
```

---

## 🎨 UI 變化

### 右下角 FAB 按鈕：
- **圖示：** ✨ → ➕ (Add icon)
- **標籤：** 「新增任務」（不變）
- **動作：** 打開任務表單（而非 AI 聊天）

### 「讓 AI 幫你拆解大任務」卡片：
- **位置：** 「待辦事項」區塊頂部（不變）
- **顏色：** Primary Container（不變）
- **圖示：** ✨ auto_awesome（不變）
- **動作：** 打開 AI 聊天介面

---

## 💡 優點

1. **更快速** ⚡
   - 直接創建任務，無需經過 AI 對話
   - 適合明確知道要做什麼的情況

2. **更直覺** 🎯
   - 「新增任務」按鈕直接對應「新增任務」動作
   - 符合用戶預期

3. **保留 AI 功能** 🤖
   - AI 拆解功能仍然可用
   - 適合需要幫助規劃的複雜任務

4. **雙軌制** 🛤️
   - 簡單任務：直接表單
   - 複雜任務：AI 協助

---

## 🧪 快速測試步驟

1. **熱重載應用** (按 `r` 或 `R` 在終端機)
2. **測試新增任務**：
   ```
   點擊 ➕ 「新增任務」
   → 填寫表單
   → 保存
   → 確認任務出現
   → 檢查終端機日誌
   ```

3. **測試 AI 功能**：
   ```
   點擊「讓 AI 幫你拆解大任務」卡片
   → 確認打開 AI 聊天
   → 測試對話功能
   ```

4. **測試資料持久化**：
   ```
   創建幾個任務
   → 完全關閉應用 (Command+Q)
   → 重新啟動
   → 確認任務都還在
   ```

---

## 🚀 下一步建議

完成測試後，可以繼續：

**選項 A：** 繼續測試 SQLite 整合
- 測試所有 CRUD 操作
- 驗證資料持久化
- 檢查錯誤處理

**選項 B：** 實現 AI 任務自動提取
- 讓 AI 聊天後自動創建任務
- 一鍵添加 AI 建議的任務
- 批量創建子任務

**選項 C：** 整合番茄鐘記錄
- 計時器完成後記錄到資料庫
- 為統計功能準備資料

---

## 📝 程式碼變更總結

```dart
// 之前
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _openAIChatScreen(context),
  icon: const Icon(Icons.auto_awesome),
  label: const Text('新增任務'),
)

// 現在
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _showAddTaskDialog(context, ref),
  icon: const Icon(Icons.add),
  label: const Text('新增任務'),
)

// 新增方法
void _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => const TaskFormDialog(),
  );
  
  if (result != null) {
    await ref.read(taskProvider.notifier).addTask(
      title: result['title'],
      description: result['description'],
      pomodoroCount: result['pomodoroCount'],
      priority: result['priority'],
    );
    
    // 顯示成功訊息
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

---

現在可以測試新功能了！🎉
