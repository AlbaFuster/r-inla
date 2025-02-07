#' Rerun an analysis
#' 
#' Rerun [inla()] on an inla-object (output from \code{link{inla}})
#' 
#' 
#' @aliases inla.rerun rerun
#' @return This function will take the result in `object`, and rerun
#' `inla` again.  If `plain` is `FALSE`, start the optimization
#' from the mode in `object` so that we can obtain an improvement the mode
#' for the hyperparameters.  Otherwise, start from the same configuration as
#' for `object`.  The returned value is an `inla`-object.
#' @seealso [inla()]
#' @examples
#' 
#' r = inla(y ~ 1,  data = data.frame(y=1:10))
#' r = inla.rerun(r)
#' 
#' @rdname rerun
#' @export inla.rerun
`inla.rerun` <- function(
                         #' @param object An `inla`-object, ie the output from an `inla`-call
                         object,
                         #' @param plain Logical. If `FALSE` (default), then make changes in
                         #' `object` to improve the performance
                         plain = FALSE)
{
    stopifnot(any(inherits(object, "inla")))

    ## need to do this, as if its true it will regenerate the linear combinations
    object$.args$control.fixed$correlation.matrix <- FALSE

    if (!plain) {
        object$.args$control.mode$result <- NULL
        object$.args$control.mode$restart <- TRUE
        object$.args$control.mode$theta <- object$mode$theta
        object$.args$control.mode$x <- object$mode$x
        object$.args$control.inla$use.directions <- object$misc$opt.directions
        object$.args$control.inla$optimise.strategy <- "plain"
        object$.args$control.inla$step.factor <- 1
        object$.args$control.inla$tolerance.step <- 1e-10

        if (identical(object$.args$control.inla$stencil, inla.set.control.inla.default()$stencil)) {
            object$.args$control.inla$stencil <- 9
        }

        h.def <- inla.set.control.inla.default()$h
        if (identical(object$.args$control.inla[["h"]], h.def)) {
            object$.args$control.inla$h <- 0.2 * object$.args$control.inla[["h"]]
        } else {
            object$.args$control.inla$h <- max(0.1 * h.def, 0.75 * object$.args$control.inla[["h"]])
        }

        tol.def <- inla.set.control.inla.default()$tolerance
        if (identical(object$.args$control.inla[["tolerance"]], tol.def)) {
            object$.args$control.inla$tolerance <- object$.args$control.inla[["tolerance"]] * 0.01
        } else {
            object$.args$control.inla$tolerance <- max(tol.def^2, object$.args$control.inla[["tolerance"]] * 0.1)
        }
    }

    new.obj <- do.call("inla", args = object$.args)
    ## revert, as variables are expanded...
    new.obj$call <- object$call

    return(new.obj)
}
