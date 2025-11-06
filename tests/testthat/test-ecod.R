test_that("ecod works with basic input", {
  set.seed(42)
  X <- matrix(rnorm(100 * 5), ncol = 5)

  result <- ecod(X)

  expect_s3_class(result, "ecod")
  expect_equal(result$n_samples, 100)
  expect_equal(result$n_features, 5)
  expect_length(result$scores, 100)
  expect_true(all(result$scores >= 0))
})

test_that("ecod handles data frames", {
  data(iris)
  result <- ecod(iris[, 1:4])

  expect_s3_class(result, "ecod")
  expect_equal(result$n_samples, 150)
  expect_equal(result$n_features, 4)
})

test_that("ecod detects obvious outliers", {
  set.seed(123)

  # Normal data
  X_normal <- matrix(rnorm(90 * 3), ncol = 3)

  # Add obvious outliers
  X_outlier <- matrix(rnorm(10 * 3, mean = 5, sd = 0.5), ncol = 3)

  X_all <- rbind(X_normal, X_outlier)

  result <- ecod(X_all)

  # Outliers should have higher scores
  outlier_scores <- result$scores[91:100]
  normal_scores <- result$scores[1:90]

  expect_true(mean(outlier_scores) > mean(normal_scores))
})

test_that("predict.ecod works correctly", {
  set.seed(456)

  X_train <- matrix(rnorm(100 * 3), ncol = 3)
  X_test <- matrix(rnorm(20 * 3), ncol = 3)

  model <- ecod(X_train)
  scores_test <- predict(model, X_test, X_train)

  expect_length(scores_test, 20)
  expect_true(all(scores_test >= 0))
})

test_that("feature_contributions returns correct format", {
  data(iris)
  model <- ecod(iris[, 1:4])

  contrib <- feature_contributions(model, 1)

  expect_length(contrib, 4)
  expect_named(contrib)
  expect_true(all(contrib >= 0))
})

test_that("get_outliers works with different thresholds", {
  set.seed(789)
  X <- matrix(rnorm(100 * 3), ncol = 3)
  model <- ecod(X)

  # Auto threshold
  outliers_auto <- get_outliers(model)
  expect_type(outliers_auto, "logical")
  expect_length(outliers_auto, 100)

  # Return indices
  outlier_idx <- get_outliers(model, return_indices = TRUE)
  expect_type(outlier_idx, "integer")
  expect_true(length(outlier_idx) <= 100)

  # Custom threshold
  outliers_99 <- get_outliers(model, threshold = "0.99")
  expect_true(sum(outliers_99) < sum(outliers_auto))
})

test_that("ecod handles edge cases", {
  # Small sample
  X_small <- matrix(rnorm(5 * 2), ncol = 2)
  expect_s3_class(ecod(X_small), "ecod")

  # Single feature
  X_single <- matrix(rnorm(100), ncol = 1)
  expect_s3_class(ecod(X_single), "ecod")

  # With normalization
  X <- matrix(rnorm(50 * 3), ncol = 3)
  result_norm <- ecod(X, normalize = TRUE)
  expect_true(result_norm$normalized)
})

test_that("ecod input validation works", {
  expect_error(ecod("not a matrix"),
               "'data' must be a matrix or data frame")
  expect_error(ecod(matrix(letters[1:20], ncol = 2)),
               "must contain only numeric values")
  expect_error(ecod(matrix(1:5, nrow = 1)),
               "must have at least 2 samples")
})

