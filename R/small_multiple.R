#' Generate a 'Small Multiple' Plot of Regression Results
#'
#' \code{small_multiple} is a function for plotting regression results of multiple models as a 'small multiple' plot
#'
#' @param x Either a tidy data.frame including results from multiple models (see 'Details') or a list of model objects that can be tidied with \code{\link[broom]{tidy}}
#' @param alpha A number setting the criterion of the confidence intervals. The default value is .05, corresponding to 95-percent confidence intervals.
#'
#' @details
#' Kastellec and Leoni (2007)
#' \code{small_multiple} takes a tidy data.frame of regression results or a list of model objects and generates a dot-and-whisker plot of the results of a single variable across the multiple models.
#'
#' Tidy data.frames to be plotted should include the variables \code{term} (names of predictors), \code{estimate} (corresponding estimates of coefficients or other quantities of interest), \code{std.error} (corresponding standard errors), and \code{model} (identifying the corresponding model).
#' In place of \code{std.error} one may substitute \code{lb} (the lower bounds of the confidence intervals of each estimate) and \code{ub} (the corresponding upper bounds).
#'
#' Alternately, \code{small_multiple} accepts as input a list of model objects that can be tidied by \code{\link[broom]{tidy}}.
#'
#' @return The function returns a \code{ggplot} object.
#'
#' @note Ideally, the y-axes of small multiple plots would vary by predictor, but small_multiple does not currently support this behavior.
#'
#' @examples
#' # Generate a tidy data.frame of regression results from six models
#' m <- list()
#' ordered_vars <- c("wt", "cyl", "disp", "hp", "gear", "am")
#' m[[1]] <- lm(mpg ~ wt, data = mtcars)
#' m123456_df <- m[[1]] %>% tidy %>% by_2sd(mtcars) %>%
#'  filter(term != "(Intercept)") %>% mutate(model = "Model 1")
#'
#' for (i in 2:6) {
#'  m[[i]] <- update(m[[i-1]], paste(". ~ . +", ordered_vars[i]))
#'  m123456_df <- rbind(m123456_df, m[[i]] %>% tidy %>% by_2sd(mtcars) %>%
#'    filter(term != "(Intercept)") %>% mutate(model = paste("Model", i)))
#' }
#'
#' # Generate a 'small multiple' plot
#' small_multiple(m123456_df)
#'
#'
#' @importFrom dplyr mutate rename arrange
#'
#' @export

small_multiple <- function(x, alpha=.05) {
    # If x is list of model objects, convert to a tidy data.frame
    df <- dw_tidy(x)

    n_vars <- length(unique(df$term))

    # Confirm number of models, get model names
    if ("model" %in% names(df)) {
        n_models <- length(unique(df$model))
    } else {
        if (length(df$term) == n_vars) {
            stop("'Small multiple' plots are used to compare results across many different models; please submit results from more than one model")
        } else {
            stop("Please add a variable named 'model' to distinguish different models")
        }
    }
    mod_names <- unique(df$model)

    df <- df %>% add_NAs(n_models, mod_names) %>%
        mutate(term = factor(term, levels = unique(term)),
               model = factor(model, levels = unique(model))) %>%
        rename(predictor = term, term = model) %>%
        mutate(model = 1) %>% arrange(predictor, desc(term))

    p <- dwplot(df, alpha = alpha) + facet_grid(predictor~.) + coord_flip()
    return(p)
}