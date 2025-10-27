# ecodR 基础使用示例
# 这个脚本展示了 ecodR 包的主要功能

# 加载包
library(ecodR)

cat("========================================\n")
cat("ecodR 包使用示例\n")
cat("========================================\n\n")

# ===== 示例 1: 使用 iris 数据集 =====
cat("示例 1: Iris 数据集异常检测\n")
cat("--------------------\n")

data(iris)
X <- iris[, 1:4]

# 训练模型
model <- ecod(X)
print(model)

# 识别异常
outliers <- get_outliers(model, threshold = "0.95", return_indices = TRUE)
cat("\n检测到的异常样本:\n")
print(outliers)

cat("\n异常样本的数据:\n")
print(iris[outliers, ])

# 可视化
cat("\n生成可视化...\n")
par(mfrow = c(2, 2))
plot(model, type = "scores")
plot(model, type = "ranked")
plot(model$scores, col = ifelse(seq_along(model$scores) %in% outliers, "red", "blue"),
     pch = 19, main = "Anomaly Scores", ylab = "Score", xlab = "Sample Index")
legend("topleft", c("Normal", "Outlier"), col = c("blue", "red"), pch = 19)
par(mfrow = c(1, 1))

# ===== 示例 2: 特征贡献分析 =====
cat("\n\n示例 2: 特征贡献分析\n")
cat("--------------------\n")

# 找到最异常的样本
most_anomalous <- which.max(model$scores)
cat("最异常的样本:", most_anomalous, "\n")
cat("异常分数:", round(model$scores[most_anomalous], 3), "\n\n")

# 特征贡献
contrib <- feature_contributions(model, most_anomalous)
cat("特征贡献度:\n")
print(round(contrib, 3))

# 可视化特征贡献
barplot(contrib, las = 2, col = "steelblue",
        main = paste("样本", most_anomalous, "的特征贡献"),
        ylab = "贡献分数")

# ===== 示例 3: 模拟数据 =====
cat("\n\n示例 3: 模拟数据异常检测\n")
cat("--------------------\n")

set.seed(42)

# 正常数据
X_normal <- data.frame(
  x1 = rnorm(500, 0, 1),
  x2 = rnorm(500, 0, 1),
  x3 = rnorm(500, 0, 1)
)

# 异常数据
X_anomaly <- data.frame(
  x1 = rnorm(50, 3, 0.5),
  x2 = rnorm(50, -3, 0.5),
  x3 = rnorm(50, 0, 3)
)

X_all <- rbind(X_normal, X_anomaly)
y_true <- c(rep("Normal", 500), rep("Anomaly", 50))

# 检测
model_sim <- ecod(X_all)

# 评估
threshold <- quantile(model_sim$scores, 0.95)
y_pred <- ifelse(model_sim$scores > threshold, "Anomaly", "Normal")

# 混淆矩阵
cat("\n混淆矩阵:\n")
confusion <- table(True = y_true, Predicted = y_pred)
print(confusion)

# 准确率、召回率、F1
TP <- confusion["Anomaly", "Anomaly"]
FP <- confusion["Normal", "Anomaly"]
FN <- confusion["Anomaly", "Normal"]
TN <- confusion["Normal", "Normal"]

precision <- TP / (TP + FP)
recall <- TP / (TP + FN)
f1 <- 2 * precision * recall / (precision + recall)

cat("\n性能指标:\n")
cat("准确率:", round((TP + TN) / sum(confusion), 3), "\n")
cat("精确率:", round(precision, 3), "\n")
cat("召回率:", round(recall, 3), "\n")
cat("F1分数:", round(f1, 3), "\n")

# 可视化
plot(model_sim$scores, 
     col = ifelse(y_true == "Anomaly", "red", "blue"),
     pch = 19, cex = 0.8,
     main = "ECOD 异常检测 - 模拟数据",
     xlab = "样本索引", ylab = "异常分数")
abline(h = threshold, col = "darkred", lwd = 2, lty = 2)
legend("topleft", 
       c("真正常", "真异常", "阈值"),
       col = c("blue", "red", "darkred"),
       pch = c(19, 19, NA),
       lty = c(NA, NA, 2),
       lwd = c(NA, NA, 2))

# ===== 示例 4: 训练-测试分离 =====
cat("\n\n示例 4: 训练-测试分离\n")
cat("--------------------\n")

# 划分数据
train_idx <- 1:100
test_idx <- 101:150

X_train <- iris[train_idx, 1:4]
X_test <- iris[test_idx, 1:4]

# 训练
model_train <- ecod(X_train)

# 预测
scores_test <- predict(model_train, X_test, X_train)

cat("训练集分数摘要:\n")
print(summary(model_train$scores))

cat("\n测试集分数摘要:\n")
print(summary(scores_test))

# 可视化比较
boxplot(list(Train = model_train$scores, Test = scores_test),
        main = "异常分数对比：训练集 vs 测试集",
        ylab = "异常分数",
        col = c("lightblue", "lightgreen"))

# ===== 示例 5: 不同阈值对比 =====
cat("\n\n示例 5: 不同阈值对比\n")
cat("--------------------\n")

model <- ecod(iris[, 1:4])

# 不同阈值
thresholds <- c("0.90", "0.95", "0.99")
for (thresh in thresholds) {
  outliers <- get_outliers(model, threshold = thresh, return_indices = TRUE)
  cat("阈值", thresh, ":", length(outliers), "个异常\n")
}

cat("\n========================================\n")
cat("示例完成！\n")
cat("========================================\n")

