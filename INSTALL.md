# ecodR 安装和使用指南

## 快速安装

### 方法 1: 从本地源码安装（推荐）

```r
# 1. 打开 R 或 RStudio

# 2. 安装 devtools（如果还没安装）
install.packages("devtools")

# 3. 从本地目录安装
devtools::install("C:/Users/LucianXu/ecodR")

# 4. 加载包
library(ecodR)

# 5. 测试
data(iris)
model <- ecod(iris[, 1:4])
print(model)
```

### 方法 2: 构建和安装

```bash
# 在终端/命令行中执行

# 1. 进入包目录的上一级
cd C:/Users/LucianXu

# 2. 构建包
R CMD build ecodR

# 3. 安装（Windows）
R CMD INSTALL ecodR_0.1.0.tar.gz

# 或者在 R 中
install.packages("C:/Users/LucianXu/ecodR_0.1.0.tar.gz", repos = NULL, type = "source")
```

### 方法 3: 在 RStudio 中直接构建

1. 在 RStudio 中打开 ecodR 项目
2. 点击 Build → Install and Restart
3. 或按 Ctrl+Shift+B

## 验证安装

```r
# 检查包是否正确安装
library(ecodR)

# 查看帮助
?ecod

# 运行示例
example(ecod)

# 运行测试（可选）
devtools::test()
```

## 依赖项

ecodR 只依赖 R 的基础包，无需额外安装其他包。

### 必需：
- R >= 3.5.0
- stats (base)
- graphics (base)

### 可选（用于示例和测试）：
- ggplot2 （更好的可视化）
- pROC （性能评估）
- testthat （运行测试）

## 完整使用示例

```r
library(ecodR)

# ===== 示例 1: 基础使用 =====
data(iris)
model <- ecod(iris[, 1:4])

# 查看结果
print(model)
summary(model)

# 识别异常
outliers <- get_outliers(model, threshold = "0.95", return_indices = TRUE)
print(outliers)

# 可视化
plot(model, type = "scores")
plot(model, type = "ranked")
plot(model, type = "features", top_n = 10)

# ===== 示例 2: 特征贡献 =====
# 最异常的样本
most_anomalous <- which.max(model$scores)
contrib <- feature_contributions(model, most_anomalous)
print(contrib)

barplot(contrib, las = 2, col = "steelblue",
        main = "Feature Contributions")

# ===== 示例 3: 预测新数据 =====
X_train <- iris[1:100, 1:4]
X_test <- iris[101:150, 1:4]

model <- ecod(X_train)
scores_test <- predict(model, X_test, X_train)
summary(scores_test)

# ===== 示例 4: 模拟数据 =====
set.seed(42)

# 正常数据
X_normal <- data.frame(
  x1 = rnorm(1000, 0, 1),
  x2 = rnorm(1000, 0, 1),
  x3 = rnorm(1000, 0, 1)
)

# 异常数据
X_anomaly <- data.frame(
  x1 = rnorm(50, 3, 0.5),
  x2 = rnorm(50, -3, 0.5),
  x3 = rnorm(50, 0, 3)
)

X_all <- rbind(X_normal, X_anomaly)

# 检测
model <- ecod(X_all)
outlier_idx <- get_outliers(model, return_indices = TRUE)

# 评估
y_true <- c(rep(0, 1000), rep(1, 50))
y_pred <- rep(0, 1050)
y_pred[outlier_idx] <- 1

table(True = y_true, Predicted = y_pred)
```

## 常见问题

### Q1: 安装时出现编译错误
A: ecodR 是纯 R 代码，不需要编译。如果出错，请检查 R 版本 >= 3.5.0

### Q2: 如何更新包？
```r
# 重新安装
devtools::install("C:/Users/LucianXu/ecodR", force = TRUE)
```

### Q3: 如何卸载包？
```r
remove.packages("ecodR")
```

### Q4: 包加载后找不到函数
```r
# 检查命名空间
ls("package:ecodR")

# 强制重新加载
detach("package:ecodR", unload = TRUE)
library(ecodR)
```

### Q5: 如何查看所有可用函数？
```r
library(help = "ecodR")
```

## 性能优化建议

```r
# 1. 对于大数据集，关闭数据存储
model <- ecod(large_data)  # 数据 > 10000 行时自动不存储原始数据

# 2. 使用矩阵而非数据框（更快）
X_matrix <- as.matrix(X_dataframe)
model <- ecod(X_matrix)

# 3. 批量预测
scores <- predict(model, X_test, X_train)  # 向量化操作
```

## 获取帮助

```r
# 函数帮助
?ecod
?predict.ecod
?plot.ecod
?feature_contributions
?get_outliers

# 查看 vignette
vignette("introduction", package = "ecodR")

# 查看所有文档
help(package = "ecodR")
```

## 报告问题

如果遇到 bug 或有功能请求，请访问：
https://github.com/yourusername/ecodR/issues

## 许可证

MIT License - 详见 LICENSE.md

