# ========================================
# 异常检测测试数据生成器
# ========================================
# 使用方法：在R中运�?source("examples/generate_anomaly_data.R")

generate_anomaly_test_data <- function(
  n_samples = 500,
  n_features = 15,
  outlier_fraction = 0.05,
  seed = 123,
  output_dir = "data"
) {

  set.seed(seed)

  # 计算样本数量
  n_outliers <- floor(n_samples * outlier_fraction)
  n_normal <- n_samples - n_outliers

  cat("========================================\n")
  cat("开始生成异常检测测试数�?..\n")
  cat("========================================\n")

  # 为不同特征分配不同的尺度
  # �?5个特征分�?个尺度组
  scale_groups <- list(
    small = 1:4,      # 特征1-4: 小尺�?(0-10)
    medium = 5:8,     # 特征5-8: 中尺�?(0-100)
    large = 9:12,     # 特征9-12: 大尺�?(0-1000)
    xlarge = 13:15    # 特征13-15: 超大尺度 (0-10000)
  )

  # 初始化均值和标准差向�?
  means <- numeric(n_features)
  sds <- numeric(n_features)

  # 为每个尺度组设置参数
  # 小尺度组 (0-10)
  means[scale_groups$small] <- runif(length(scale_groups$small),
                                     min = 2, max = 8)
  sds[scale_groups$small] <- runif(length(scale_groups$small),
                                   min = 0.5, max = 1.5)

  # 中尺度组 (0-100)
  means[scale_groups$medium] <- runif(length(scale_groups$medium),
                                      min = 30, max = 70)
  sds[scale_groups$medium] <- runif(length(scale_groups$medium),
                                    min = 5, max = 15)

  # 大尺度组 (0-1000)
  means[scale_groups$large] <- runif(length(scale_groups$large),
                                     min = 300, max = 700)
  sds[scale_groups$large] <- runif(length(scale_groups$large),
                                   min = 50, max = 150)

  # 超大尺度�?(0-10000)
  means[scale_groups$xlarge] <- runif(length(scale_groups$xlarge),
                                      min = 3000, max = 7000)
  sds[scale_groups$xlarge] <- runif(length(scale_groups$xlarge),
                                    min = 500, max = 1500)

  # 生成正常样本（多元正态分布）
  normal_data <- matrix(nrow = n_normal, ncol = n_features)
  for (i in 1:n_features) {
    normal_data[, i] <- rnorm(n_normal, mean = means[i], sd = sds[i])
  }

  # 生成异常样本（偏离正常分布）
  outlier_data <- matrix(nrow = n_outliers, ncol = n_features)
  for (i in 1:n_features) {
    # 随机选择偏离方向（高值或低值异常）
    direction <- sample(c(-1, 1), n_outliers, replace = TRUE)
    # 异常程度：偏�?-6个标准差
    deviation <- runif(n_outliers, min = 3, max = 6)
    outlier_data[, i] <- means[i] + direction * deviation * sds[i]
  }

  # 合并数据
  all_data <- rbind(normal_data, outlier_data)
  colnames(all_data) <- paste0("Feature_", 1:n_features)

  # 创建标签
  labels <- c(rep(0, n_normal), rep(1, n_outliers))

  # 随机打乱数据
  shuffle_indices <- sample(1:n_samples)
  shuffled_data <- all_data[shuffle_indices, ]
  shuffled_labels <- labels[shuffle_indices]

  # 找出异常数据的行�?
  outlier_rows <- which(shuffled_labels == 1)

  # 创建数据�?
  test_dataset <- as.data.frame(shuffled_data)
  test_dataset$is_outlier <- shuffled_labels

  # 创建输出目录（如果不存在�?
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 保存文件
  data_file <- file.path(output_dir, "anomaly_test_data.csv")
  outlier_file <- file.path(output_dir, "outlier_rows.csv")

  write.csv(test_dataset, data_file, row.names = FALSE)
  write.csv(
    data.frame(row_number = sort(outlier_rows)),
    outlier_file,
    row.names = FALSE
  )

  # 打印结果
  cat("========================================\n")
  cat("数据生成完成！\n")
  cat("========================================\n")
  cat("总样本数:", n_samples, "\n")
  cat("特征�?", n_features, "\n")
  cat("正常样本�?", n_normal, "\n")
  cat("异常样本�?", n_outliers, "\n")
  cat("异常比例:", outlier_fraction * 100, "%\n")
  cat("========================================\n")
  cat("特征尺度分布:\n")
  cat("- Feature_1-4:   小尺�?(0-10)\n")
  cat("- Feature_5-8:   中尺�?(0-100)\n")
  cat("- Feature_9-12:  大尺�?(0-1000)\n")
  cat("- Feature_13-15: 超大尺度 (0-10000)\n")
  cat("========================================\n")
  cat("异常数据所在行号（�?, length(outlier_rows), "行）:\n")
  cat(sort(outlier_rows), "\n")
  cat("========================================\n")
  cat("文件已保存到:\n")
  cat("1.", data_file, "\n")
  cat("2.", outlier_file, "\n")
  cat("========================================\n\n")

  # 显示各尺度特征的统计
  cat("\n各尺度特征统�?\n")
  cat("\n小尺度特�?(Feature_1-4):\n")
  print(summary(test_dataset[, 1:4]))

  cat("\n中尺度特�?(Feature_5-8):\n")
  print(summary(test_dataset[, 5:8]))

  cat("\n大尺度特�?(Feature_9-12):\n")
  print(summary(test_dataset[, 9:12]))

  cat("\n超大尺度特征 (Feature_13-15):\n")
  print(summary(test_dataset[, 13:15]))

  # 返回结果（隐式返回）
  invisible(list(
    data = test_dataset[, -ncol(test_dataset)],
    labels = shuffled_labels,
    outlier_rows = sort(outlier_rows),
    data_with_labels = test_dataset
  ))
}

# 运行函数生成数据
cat("\n正在生成测试数据...\n\n")
result <- generate_anomaly_test_data(
  n_samples = 500,
  n_features = 15,
  outlier_fraction = 0.05,
  seed = 123
)

cat("\n========================================\n")
cat("数据生成完成！可以开始使用了。\n")
cat("========================================\n")

