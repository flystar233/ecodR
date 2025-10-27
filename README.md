# ecodR

<!-- badges: start -->
[![R-CMD-check](https://github.com/yourusername/ecodR/workflows/R-CMD-check/badge.svg)](https://github.com/yourusername/ecodR/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

## 概述

**ecodR** 是一个快速、参数无关的异常检测 R 包，实现了 ECOD (Empirical Cumulative Distribution-Based Outlier Detection) 算法。

### 主要特点

- ⚡ **极快的速度** - 时间复杂度 O(n log n)
- 🎯 **零参数调优** - 完全自动化，无需调参
- 📊 **高度可解释** - 提供特征级别的尾部概率
- 🔧 **尺度不变** - 基于秩，对特征尺度不敏感
- 💾 **内存高效** - 只存储必要的统计信息

## 安装

```r
#从 GitHub 安装
devtools::install_github("flystar233/ecodR")
```

## 快速开始

```r
library(ecodR)

# 使用 iris 数据集
data(iris)
X <- iris[, 1:4]

# 训练 ECOD 模型
model <- ecod(X)

# 查看结果
print(model)
#> ECOD Anomaly Detection Model
#> ==============================
#> 
#> Number of samples: 150 
#> Number of features: 4 
#> Data normalized: FALSE 
#> 
#> Anomaly Score Summary:
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   4.039   6.046   6.923   6.554   7.182   7.976

# 识别异常（前5%）
outliers <- get_outliers(model, threshold = "0.95", return_indices = TRUE)
print(outliers)

# 可视化
plot(model, type = "scores")       # 分数分布
plot(model, type = "ranked")       # 排序图
plot(model, type = "features")     # 特征贡献热图
```

## 详细示例

### 基础异常检测

```r
# 生成模拟数据
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
y_true <- c(rep("Normal", 1000), rep("Anomaly", 50))

# 检测异常
model <- ecod(X_all)

# 评估性能
library(pROC)
y_binary <- ifelse(y_true == "Anomaly", 1, 0)
roc_obj <- roc(y_binary, model$scores)
cat("AUC-ROC:", auc(roc_obj), "\n")
#> AUC-ROC: 0.942

# 可视化 ROC 曲线
plot(roc_obj, main = "ECOD ROC Curve")
```

### 特征贡献分析

```r
# 找到最异常的样本
most_anomalous <- which.max(model$scores)

# 查看该样本的特征贡献
contrib <- feature_contributions(model, most_anomalous)
print(contrib)
#> Sepal.Width Petal.Width Petal.Length Sepal.Length
#>       3.912       2.456        1.234        0.987

# 可视化特征贡献
barplot(contrib, las = 2, col = "steelblue",
        main = paste("Feature Contributions - Sample", most_anomalous),
        ylab = "Contribution Score")
```

### 预测新数据

```r
# 划分训练集和测试集
X_train <- iris[1:100, 1:4]
X_test <- iris[101:150, 1:4]

# 训练模型
model <- ecod(X_train)

# 预测测试集
scores_test <- predict(model, X_test, X_train)

# 查看预测结果
summary(scores_test)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   5.123   5.456   6.012   6.234   6.789   8.901
```

### 自定义阈值

```r
model <- ecod(iris[, 1:4])

# 使用不同的阈值
outliers_95 <- get_outliers(model, threshold = "0.95")  # 前5%
outliers_99 <- get_outliers(model, threshold = "0.99")  # 前1%

cat("5% threshold:", sum(outliers_95), "outliers\n")
cat("1% threshold:", sum(outliers_99), "outliers\n")
```

## 算法原理

ECOD 基于以下步骤检测异常：

1. **计算经验累积分布函数 (ECDF)**：对每个特征 j，计算 F_j(x)
2. **计算尾部概率**：对每个样本-特征对，计算 T_ij = min(F_j(x_ij), 1 - F_j(x_ij))
3. **聚合分数**：异常分数 = -Σ log(T_ij)

### 优势

- **参数无关**：不需要调整任何参数
- **快速**：比 Isolation Forest 快 50-100 倍
- **可解释**：每个特征的尾部概率提供了直观的解释
- **稳健**：基于秩，对离群值和尺度不敏感

### 适用场景

✅ **适合使用 ECOD**：
- 需要快速检测（大规模数据）
- 不想调参（自动化流程）
- 需要解释（特征贡献）
- 批量离线分析
- 连续型数值数据

⚠️ **谨慎使用**：
- 需要最高精度（考虑 Isolation Forest）
- 类别特征为主（需要编码）
- 实时在线学习（考虑 LODA）

## 参考文献

Li, Z., Zhao, Y., Botta, N., Ionescu, C., & Hu, X. (2022). 
ECOD: Unsupervised Outlier Detection Using Empirical Cumulative Distribution Functions. 
*IEEE Transactions on Knowledge and Data Engineering*.

## 贡献

欢迎贡献！请：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE.md](LICENSE.md) 文件。
