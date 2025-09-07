# 計時器畫面大螢幕居中修復

## 問題描述
在大螢幕手機或平板設備上，計時器畫面的內容（特別是"當前任務"卡片和計時器圓圈）可能不會在畫面中央正確顯示，影響使用者體驗。

## 解決方案

### 修改內容
對 `lib/screens/timer_screen.dart` 進行了以下改進：

1. **使用 LayoutBuilder**：添加了 `LayoutBuilder` 來獲取可用空間的尺寸
2. **Center 包裝**：使用 `Center` 小部件確保內容在水平方向居中
3. **ConstrainedBox 約束**：添加了 `ConstrainedBox` 來：
   - 設置最小高度為可用高度，確保垂直居中
   - 設置最大寬度為 400px，避免在平板上內容過寬
4. **改進滾動物理**：使用 `ClampingScrollPhysics` 替代 `NeverScrollableScrollPhysics`，提供更好的滾動體驗

### 具體修改

```dart
// 修改前
Expanded(
  child: SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 內容...
      ],
    ),
  ),
)

// 修改後
Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: 400, // 限制最大寬度
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 內容...
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
)
```

## 改進效果

### ✅ 解決的問題：
1. **大螢幕居中**：在大螢幕設備上，任務卡片和計時器圓圈現在會正確居中顯示
2. **平板適配**：在平板設備上限制最大寬度，避免內容過度拉伸
3. **響應式設計**：自動適應不同螢幕尺寸
4. **滾動體驗**：在內容超出螢幕時提供合適的滾動行為

### 📱 支援的設備：
- 小螢幕手機（原有體驗保持不變）
- 大螢幕手機（改善居中顯示）
- 平板設備（限制寬度，保持可讀性）
- 折疊螢幕設備（動態適應）

### 🎯 設計原則：
1. **居中對齊**：主要內容始終在螢幕中央
2. **寬度限制**：避免在寬螢幕上內容過度拉伸
3. **響應式**：自動適應各種螢幕尺寸
4. **一致性**：保持原有的視覺設計風格

## 測試結果
- ✅ 編譯成功
- ✅ 無語法錯誤
- ✅ 保持原有功能完整性
- ✅ 適配多種螢幕尺寸

這個修改確保了計時器畫面在各種設備上都能提供最佳的使用者體驗。
