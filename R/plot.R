#' Plot Method for ECOD Objects
#'
#' @description
#' Visualizes anomaly scores and feature contributions from an ECOD model.
#'
#' @param x An ecod object.
#' @param type Character string specifying the plot type. One of:
#'   \itemize{
#'     \item "scores" - Histogram of anomaly scores (default)
#'     \item "ranked" - Ranked plot of anomaly scores
#'     \item "features" - Feature contribution heatmap
#'   }
#' @param threshold Numeric. Threshold for marking outliers. If NULL (default),
#'   uses the 95th percentile.
#' @param top_n Integer. For type="features", number of top anomalous
#'   samples to show.
#' @param ... Additional arguments passed to plotting functions.
#'
#' @examples
#' model <- ecod(iris[, 1:4])
#' plot(model, type = "scores")
#' plot(model, type = "ranked")
#' plot(model, type = "features", top_n = 10)
#'
#' @export
plot.ecod <- function(x, type = c("scores", "ranked", "features"),
                      threshold = NULL, top_n = 10, ...) {

  type <- match.arg(type)

  # Set default threshold
  if (is.null(threshold)) {
    threshold <- quantile(x$scores, 0.95)
  }

  if (type == "scores") {
    # Histogram of anomaly scores
    hist(x$scores,
         breaks = 30,
         main = "Distribution of Anomaly Scores",
         xlab = "Anomaly Score",
         ylab = "Frequency",
         col = "lightblue",
         border = "white",
         ...)
    abline(v = threshold, col = "red", lwd = 2, lty = 2)
    legend("topright",
           legend = c(paste0("Threshold (", round(threshold, 2), ")")),
           col = "red", lty = 2, lwd = 2)

  } else if (type == "ranked") {
    # Ranked plot
    sorted_scores <- sort(x$scores, decreasing = FALSE)
    is_outlier <- sorted_scores > threshold

    plot(seq_along(sorted_scores), sorted_scores,
         type = "h",
         col = ifelse(is_outlier, "red", "blue"),
         lwd = 2,
         main = "Ranked Anomaly Scores",
         xlab = "Rank",
         ylab = "Anomaly Score",
         ...)
    abline(h = threshold, col = "red", lwd = 2, lty = 2)

    n_outliers <- sum(is_outlier)
    legend("topleft",
           legend = c("Normal", "Outlier",
                      paste0("Threshold (n=", n_outliers, ")")),
           col = c("blue", "red", "red"),
           lty = c(1, 1, 2),
           lwd = 2)

  } else if (type == "features") {
    # Feature contribution heatmap
    top_idx <- order(x$scores, decreasing = TRUE)[
      seq_len(min(top_n, x$n_samples))
    ]

    # Compute feature contributions (-log of tail probs)
    contributions <- -log(x$tail_probs[top_idx, , drop = FALSE])

    # Create heatmap
    par(mar = c(5, 8, 4, 2))
    image(t(contributions),
          col = hcl.colors(12, "YlOrRd", rev = TRUE),
          xlab = "Feature",
          ylab = "",
          main = paste("Feature Contributions (Top",
                       length(top_idx), "Outliers)"),
          axes = FALSE,
          ...)

    # Add axes
    axis(1, at = seq(0, 1, length.out = x$n_features),
         labels = x$feature_names, las = 2)
    axis(2, at = seq(0, 1, length.out = length(top_idx)),
         labels = paste("Sample", top_idx), las = 1)

    # Add color bar legend
    par(mar = c(5, 4, 4, 2))
  }

  invisible(x)
}


#' Get Feature Contributions for a Sample
#'
#' @description
#' Computes the contribution of each feature to a sample's anomaly score,
#' along with the tail probabilities.
#'
#' @param object An ecod object.
#' @param sample_id Integer or numeric. Index of the sample to analyze.
#' @param as_dataframe Logical. If TRUE (default), returns a data frame with
#'   feature names, tail probabilities, and contributions. If FALSE, returns
#'   a named numeric vector of contributions only (for backward compatibility).
#'
#' @return If as_dataframe=TRUE, a data frame with columns:
#' \item{feature}{Feature name}
#' \item{tail_probability}{Tail probability (closer to 0 = more extreme)}
#' \item{contribution}{Contribution score (-log of tail probability)}
#'
#' If as_dataframe=FALSE, a named numeric vector of contributions,
#' sorted in decreasing order.
#'
#' @examples
#' model <- ecod(iris[, 1:4])
#'
#' # Get contributions as data frame (default)
#' most_anomalous <- which.max(model$scores)
#' contributions <- feature_contributions(model, most_anomalous)
#' print(contributions)
#'
#' # Get as vector (old behavior)
#' contrib_vector <- feature_contributions(model, most_anomalous,
#'                                         as_dataframe = FALSE)
#'
#' # Visualize
#' barplot(contributions$contribution,
#'         names.arg = contributions$feature,
#'         las = 2, col = "steelblue",
#'         main = paste("Feature Contributions - Sample", most_anomalous))
#'
#' @export
feature_contributions <- function(object, sample_id, as_dataframe = TRUE) {

  if (!inherits(object, "ecod")) {
    stop("'object' must be of class 'ecod'")
  }

  if (sample_id < 1 || sample_id > object$n_samples) {
    stop("'sample_id' must be between 1 and ", object$n_samples)
  }

  # Get tail probabilities and feature names
  tail_probs <- object$tail_probs[sample_id, ]
  feature_names <- object$feature_names

  # Compute contributions as -log(tail_prob)
  contributions <- -log(tail_probs)

  if (as_dataframe) {
    # Create data frame
    result <- data.frame(
      feature = feature_names,
      tail_probability = as.numeric(tail_probs),
      contribution = as.numeric(contributions),
      stringsAsFactors = FALSE
    )

    # Sort by contribution (decreasing)
    result <- result[order(result$contribution, decreasing = TRUE), ]
    rownames(result) <- NULL

    return(result)
  } else {
    # Return as named vector (backward compatibility)
    names(contributions) <- feature_names
    contributions <- sort(contributions, decreasing = TRUE)
    return(contributions)
  }
}


#' Identify Outliers Based on Threshold
#'
#' @description
#' Returns indices or logical vector indicating which samples are outliers.
#'
#' @param object An ecod object.
#' @param threshold Numeric threshold or character string. If numeric,
#'   samples with scores above this value are considered outliers.
#'   If character, one of:
#'   \itemize{
#'     \item "auto" - Uses 95th percentile (default)
#'     \item A percentile like "0.95", "0.99"
#'   }
#' @param return_indices Logical. If TRUE, returns indices of outliers.
#'   If FALSE (default), returns a logical vector.
#'
#' @return Either a logical vector (if return_indices=FALSE) or integer vector
#'   of outlier indices (if return_indices=TRUE).
#'
#' @examples
#' model <- ecod(iris[, 1:4])
#'
#' # Get logical vector
#' is_outlier <- get_outliers(model)
#' table(is_outlier)
#'
#' # Get indices
#' outlier_indices <- get_outliers(model, return_indices = TRUE)
#' print(outlier_indices)
#'
#' # Use custom threshold
#' outliers <- get_outliers(model, threshold = 0.99)
#'
#' @export
get_outliers <- function(object, threshold = "auto", return_indices = FALSE) {

  if (!inherits(object, "ecod")) {
    stop("'object' must be of class 'ecod'")
  }

  # Determine threshold
  if (is.character(threshold)) {
    if (threshold == "auto") {
      threshold_value <- quantile(object$scores, 0.95)
    } else {
      percentile <- as.numeric(threshold)
      if (is.na(percentile) || percentile <= 0 || percentile >= 1) {
        stop(
          "If character, 'threshold' must be 'auto' or a valid ",
          "percentile string"
        )
      }
      threshold_value <- quantile(object$scores, percentile)
    }
  } else if (is.numeric(threshold)) {
    threshold_value <- threshold
  } else {
    stop("'threshold' must be numeric or character")
  }

  # Identify outliers
  is_outlier <- object$scores > threshold_value

  if (return_indices) {
    return(which(is_outlier))
  } else {
    return(is_outlier)
  }
}

