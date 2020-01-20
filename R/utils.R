#'  Fast euclidean distance
#'
#'  This function returns Euclidean distance between all combination of rows of a data matrix. Much faster than 'dist' when you use large matrix (n> 100.000.000).
#'
#' @param m matrix
#' @return The sum of \code{x} and \code{y}.
#' @examples
#' M <-  matrix(rnorm(100), nrow = 5)
#' euc_dist(M)

euc_dist <- function(m) {
    mtm <- Matrix::tcrossprod(m)
    sq <- rowSums(m * m)
    sqrt(outer(sq, sq, "+") - 2 * mtm)
}

