#' ECOD: Empirical Cumulative Distribution-Based Outlier Detection
#'
#' @description
#' Implements the ECOD algorithm for fast, parameter-free anomaly detection.
#' ECOD uses empirical cumulative distribution functions (ECDF) to compute
#' tail probabilities for each feature and aggregates them to identify outliers.
#'
#' @param data A numeric matrix or data frame. Rows represent samples
#'   and columns represent features.
#' @param normalize Logical. Whether to standardize the data before
#'   computing tail probabilities. Default is FALSE as ECOD is
#'   scale-invariant.
#'
#' @return An object of class "ecod" containing:
#' \item{scores}{Anomaly scores for each sample. Higher scores
#'   indicate more anomalous samples.}
#' \item{tail_probs}{Matrix of tail probabilities for each sample-feature pair.}
#' \item{data}{The input data (if retained).}
#' \item{n_samples}{Number of samples.}
#' \item{n_features}{Number of features.}
#' \item{feature_names}{Names of features.}
#'
#' @details
#' ECOD computes the anomaly score as:
#' \deqn{score_i = -\sum_{j=1}^{d} \log(\min(F_j(x_{ij}), 1 - F_j(x_{ij})))}
#' where \eqn{F_j} is the empirical CDF of feature j.
#'
#' The method has several advantages:
#' \itemize{
#'   \item No parameters to tune
#'   \item Extremely fast (O(n log n))
#'   \item Scale-invariant (uses ranks)
#'   \item Interpretable (feature-level tail probabilities)
#' }
#'
#' \strong{Handling Categorical Features:}
#'
#' ECOD requires numeric features. If a data frame contains
#' non-numeric columns (factors, characters), they will be
#' automatically filtered out with a warning.
#' To properly include categorical information:
#'
#' \itemize{
#'   \item \strong{One-Hot Encoding} (recommended for few categories):
#'     \code{X <- model.matrix(~ . - 1, data = your_data)}
#'   \item \strong{Frequency Encoding} (for many categories):
#'     Replace categories with their occurrence frequencies
#'   \item \strong{Label Encoding} (only for ordinal features):
#'     Convert ordered categories to integers
#' }
#'
#' See examples for demonstrations of encoding methods.
#'
#' @references
#' Li, Z., Zhao, Y., Botta, N., Ionescu, C., & Hu, X. (2022).
#' ECOD: Unsupervised Outlier Detection Using Empirical Cumulative
#' Distribution Functions. IEEE Transactions on Knowledge and Data
#' Engineering.
#'
#' @examples
#' # Basic usage with iris dataset
#' data(iris)
#' model <- ecod(iris[, 1:4])
#' print(model)
#' summary(model$scores)
#'
#' # Identify top 5% as outliers
#' threshold <- quantile(model$scores, 0.95)
#' outliers <- which(model$scores > threshold)
#' print(outliers)
#'
#' # Visualize anomaly scores
#' plot(model)
#'
#' # Automatic filtering of categorical features
#' # Species column (factor) will be automatically removed with warning
#' model_auto <- ecod(iris)  # Automatically filters Species column
#'
#' # Proper way to handle categorical features: One-Hot encoding
#' iris_encoded <- model.matrix(~ . - 1, data = iris[, c(1:4, 5)])
#' model_encoded <- ecod(iris_encoded)
#'
#' @export
ecod <- function(data, normalize = FALSE) {

  # Input validation
  if (!is.matrix(data) && !is.data.frame(data)) {
    stop("'data' must be a matrix or data frame")
  }

  # Handle categorical features if data is a data frame
  if (is.data.frame(data)) {
    # Detect non-numeric columns
    numeric_cols <- sapply(data, is.numeric)
    non_numeric_cols <- names(data)[!numeric_cols]

    if (length(non_numeric_cols) > 0) {
      # Categorical features detected
      warning(
        "Categorical/non-numeric features detected and removed:\n  ",
        paste(non_numeric_cols, collapse = ", "),
        "\n  ECOD only works with numeric features.",
        "\n  Consider encoding categorical features using:",
        "\n    - One-Hot encoding: model.matrix(~ . - 1, data)",
        "\n    - Frequency encoding",
        "\n  See ?ecod for more information.",
        call. = FALSE
      )

      # Filter to keep only numeric columns
      data <- data[, numeric_cols, drop = FALSE]

      # Check if any numeric columns remain
      if (ncol(data) == 0) {
        stop(
          "No numeric features found after filtering. ",
          "Cannot proceed with ECOD.",
          call. = FALSE
        )
      }

      cat("Proceeding with", ncol(data), "numeric feature(s):",
          paste(names(data), collapse = ", "), "\n")
    }
  }

  # Convert to matrix
  X <- as.matrix(data)

  # Final check for non-numeric data (safety check)
  if (!is.numeric(X)) {
    stop(
      "'data' must contain only numeric values. ",
      "Please ensure all columns are numeric or use a data frame ",
      "for automatic filtering.",
      call. = FALSE
    )
  }

  # Get dimensions
  n <- nrow(X)
  d <- ncol(X)

  if (n < 2) {
    stop("'data' must have at least 2 samples")
  }

  if (d < 1) {
    stop("'data' must have at least 1 feature")
  }

  # Get feature names
  feature_names <- colnames(X)
  if (is.null(feature_names)) {
    feature_names <- paste0("V", seq_len(d))
  }

  # Optional normalization
  if (normalize) {
    X <- scale(X)
  }

  # Compute tail probabilities for each feature
  tail_probs <- sapply(seq_len(d), function(j) {
    feature <- X[, j]

    # Handle constant features
    if (sd(feature) == 0) {
      return(rep(0.5, n))
    }

    # Compute ranks (average method for ties)
    ranks <- rank(feature, ties.method = "average")

    # Left tail probability
    left_tail <- ranks / n

    # Right tail probability
    right_tail <- 1 - left_tail

    # Return minimum (two-tailed)
    pmin(left_tail, right_tail)
  })

  # Set column names
  colnames(tail_probs) <- feature_names

  # Add small epsilon to avoid log(0)
  epsilon <- .Machine$double.eps
  tail_probs <- pmax(tail_probs, epsilon)

  # Compute anomaly scores (negative log-likelihood)
  anomaly_scores <- -rowSums(log(tail_probs))

  # Create result object
  result <- structure(
    list(
      scores = anomaly_scores,
      tail_probs = tail_probs,
      data = if (n <= 10000) data else NULL,  # Only store for small datasets
      n_samples = n,
      n_features = d,
      feature_names = feature_names,
      normalized = normalize
    ),
    class = "ecod"
  )

  result
}


#' Predict Anomaly Scores for New Data
#'
#' @description
#' Predicts anomaly scores for new data using a trained ECOD model.
#'
#' @param object An ecod object from \code{\link{ecod}}.
#' @param newdata A numeric matrix or data frame with the same number
#'   of features as the training data.
#' @param X_train The training data used to fit the original model. Required for
#'   computing ECDFs.
#' @param ... Additional arguments (currently unused).
#'
#' @return A numeric vector of anomaly scores for the new samples.
#'
#' @examples
#' # Train on first 100 samples
#' X_train <- iris[1:100, 1:4]
#' model <- ecod(X_train)
#'
#' # Predict on remaining samples
#' X_test <- iris[101:150, 1:4]
#' scores_test <- predict(model, X_test, X_train)
#' summary(scores_test)
#'
#' @export
predict.ecod <- function(object, newdata, X_train, ...) {

  if (!inherits(object, "ecod")) {
    stop("'object' must be of class 'ecod'")
  }

  if (missing(X_train)) {
    stop("'X_train' is required for computing ECDFs")
  }

  # Convert to matrices
  newdata <- as.matrix(newdata)
  X_train <- as.matrix(X_train)

  # Check dimensions
  if (ncol(newdata) != object$n_features) {
    stop("'newdata' must have ", object$n_features, " features")
  }

  if (ncol(X_train) != object$n_features) {
    stop("'X_train' must have ", object$n_features, " features")
  }

  d <- ncol(newdata)

  # Compute tail probabilities for new data
  tail_probs_new <- sapply(seq_len(d), function(j) {
    # Build ECDF from training data
    F_train <- ecdf(X_train[, j])

    # Evaluate on new data
    left_tail <- F_train(newdata[, j])
    right_tail <- 1 - left_tail

    pmin(left_tail, right_tail)
  })

  # Avoid log(0)
  epsilon <- .Machine$double.eps
  tail_probs_new <- pmax(tail_probs_new, epsilon)

  # Compute anomaly scores
  anomaly_scores_new <- -rowSums(log(tail_probs_new))

  as.vector(anomaly_scores_new)
}


#' Print Method for ECOD Objects
#'
#' @param x An ecod object.
#' @param ... Additional arguments passed to print.
#'
#' @export
print.ecod <- function(x, ...) {
  cat("ECOD Anomaly Detection Model\n")
  cat("==============================\n\n")
  cat("Number of samples:", x$n_samples, "\n")
  cat("Number of features:", x$n_features, "\n")
  cat("Data normalized:", x$normalized, "\n\n")

  cat("Anomaly Score Summary:\n")
  print(summary(x$scores))

  cat("\nTop 5 Most Anomalous Samples:\n")
  top_idx <- order(x$scores, decreasing = TRUE)[1:min(5, x$n_samples)]
  top_df <- data.frame(
    Sample = top_idx,
    Score = round(x$scores[top_idx], 3)
  )
  print(top_df, row.names = FALSE)

  invisible(x)
}


#' Summary Method for ECOD Objects
#'
#' @param object An ecod object.
#' @param ... Additional arguments (currently unused).
#'
#' @export
summary.ecod <- function(object, ...) {
  cat("ECOD Model Summary\n")
  cat("==================\n\n")

  cat("Data Dimensions:\n")
  cat("  Samples:", object$n_samples, "\n")
  cat("  Features:", object$n_features, "\n\n")

  cat("Anomaly Scores:\n")
  cat("  Min:", round(min(object$scores), 3), "\n")
  cat("  Q1:", round(quantile(object$scores, 0.25), 3), "\n")
  cat("  Median:", round(median(object$scores), 3), "\n")
  cat("  Mean:", round(mean(object$scores), 3), "\n")
  cat("  Q3:", round(quantile(object$scores, 0.75), 3), "\n")
  cat("  Max:", round(max(object$scores), 3), "\n\n")

  # Check for potential outliers (top 5%)
  threshold_95 <- quantile(object$scores, 0.95)
  n_outliers_95 <- sum(object$scores > threshold_95)

  cat("Potential Outliers (top 5%):", n_outliers_95, "\n")
  cat("Threshold (95th percentile):", round(threshold_95, 3), "\n")

  invisible(object)
}
