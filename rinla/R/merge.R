#' @title Merge a mixture of `inla`-objects
#' 
#' @description 
#' The function `merge.inla` implements method `merge` for
#' `inla`-objects. `merge.inla` is a wrapper for the function
#' `inla.merge`. The interface is slightly different, `merge.inla` is
#' more tailored for interactive use, whereas `inla.merge` is better in
#' general code.
#' 
#' `inla.merge` is intented for merging a mixture of `inla`-objects,
#' each run with the same formula and settings, except for a set of
#' hyperparameters, or other parameters in the model, 
#' that are fixed to different values. Using this function, we
#' can then integrate over these hyperparameters using (unnormalized)
#' integration weights `prob`. The main objects to be merged, are the
#' summary statistics and marginal densities (like for hyperparameters, fixed,
#' random, etc).  Not all entries in the object can be merged, and by default
#' these are inheritated from the first object in the list, while some are just
#' set to `NULL`.  Those objectes that are merged, will be listed if run
#' with option `verbose=TRUE`.
#' 
#' Note that merging hyperparameter in the user-scale is prone to
#' discretization error in general, so it is more stable to convert the
#' marginal of the hyperparameter from the merged internal scale to the
#' user-scale. (This is not done by this function.)
#' 
#' @aliases inla.merge merge.inla
#' @param x An `inla`-object to be merged
#' @param y An `inla`-object to be merged
#' @param ... Additional `inla`-objects to be merged
#' @param loo List of `inla`-objects to be merged
#' @param prob The mixture of (possibly unnormalized) probabilities
#' @param mc.cores The number of cores to use in `parallel::mclapply`. If
#' `is.null(mc.cores)`, then check `getOption("mc.cores")` and
#' `inla.getOption("num.threads")` in that order.
#' @param verbose Turn on verbose-output or not
#' @return A merged `inla`-object.
#' @author Havard Rue \email{hrue@@r-inla.org}
#' @examples
#' 
#'  set.seed(123)
#'  n = 100
#'  y = rnorm(n)
#'  y[1:10] = NA
#'  x = rnorm(n)
#'  z1 = runif(n)
#'  z2 = runif(n)*n
#'  idx = 1:n
#'  idx2 = 1:n
#'  lc1 = inla.make.lincomb(idx = c(1, 2, 3))
#'  names(lc1) = "lc1"
#'  lc2 = inla.make.lincomb(idx = c(0, 1, 2, 3))
#'  names(lc2) = "lc2"
#'  lc3 = inla.make.lincomb(idx = c(0, 0, 1, 2, 3))
#'  names(lc3) = "lc3"
#'  lc = c(lc1, lc2, lc3)
#'  rr = list()
#'  for (logprec in c(0, 1, 2))
#'      rr[[length(rr)+1]] = inla(y ~ 1 + x + f(idx, z1) + f(idx2, z2),
#'               lincomb = lc,
#'               control.family = list(hyper = list(prec = list(initial = logprec))),
#'               control.predictor = list(compute = TRUE, link = 1),
#'               data = data.frame(y, x, idx, idx2, z1, z2))
#'  r = inla.merge(rr, prob = seq_along(rr), verbose=TRUE)
#'  summary(r)
#'  
#' @rdname merge
#' @method merge inla
#' @export
`merge.inla` <- function(x, y, ..., prob = rep(1, length(list(x, y, ...))), verbose = FALSE) {
    return(inla.merge(loo = list(x, y, ...), prob = prob, verbose = verbose))
}

#' @rdname merge
#' @export inla.merge
`inla.merge` <- function(loo, prob = rep(1, length(loo)), mc.cores = NULL, verbose = FALSE) {
    nm <- "disable.inla.merge.warning"
    if (!exists(nm, envir = inla.get.inlaEnv())) {
        warning("This function is experimental.", immediate. = TRUE)
        assign(nm, TRUE, envir = inla.get.inlaEnv())
    }

    verboze <- function(..., sep = "") {
        if (verbose) {
            cat("inla.merge: ", ..., "\n", sep = sep)
        }
    }

    merge.marginals <- function(lom, prob, nx = 128, eps.y = 1e-6) {
        ## compute the (min, median, max) for each marginal, and then the min, median, max of
        ## those again.
        xs <- matrix(unlist(lapply(
            lom,
            function(m) {
                xx <- m[, "x"]
                return(c(min(xx), median(xx), max(xx)))
            }
        )), nrow = 3)
        x.min <- min(xs[1, ])
        x.med <- median(xs[2, ])
        x.max <- max(xs[3, ])
        ## we guess the transformation... In any case, it should not to be to bad.
        if (x.min > 0 && x.max < 1) {
            ## probability
            m1 <- function(x) 1.0 / (1.0 + exp(-x))
            m1i <- function(x) log(x / (1.0 - x))
        } else if (x.min > 0) {
            ## this is a positive marginal. Choose the scale that make is more symmetric
            if (abs((x.med - x.min) / (x.max - x.min) - 0.5) <
                abs((log(x.med) - log(x.min)) / (log(x.max) - log(x.min)) - 0.5)) {
                ## linear
                m1 <- m1i <- function(x) x
            } else {
                ## log
                m1 <- function(x) exp(x)
                m1i <- function(x) log(x)
            }
        } else {
            ## use a linear mapping
            m1 <- m1i <- function(x) x
        }
        xx <- m1(seq(m1i(x.min), m1i(x.max), length.out = nx))
        yy <- rep(0, nx)
        for (i in seq_along(lom)) {
            yy <- yy + prob[i] * inla.dmarginal(xx, lom[[i]])
        }
        ## remove points not needed
        idx.keep <- (yy > eps.y * max(yy))
        marg <- inla.smarginal(cbind(x = xx[idx.keep], y = yy[idx.keep]), factor = 2L, keep.type = TRUE)
        return(marg)
    }

    merge.summary <- function(los, prob) {
        n <- length(los)
        stopifnot(length(prob) == n)
        m <- nrow(los[[1]])
        m1 <- numeric(m)
        m2 <- numeric(m)
        prob <- prob / sum(prob)
        for (i in 1:n) {
            m1 <- m1 + prob[i] * los[[i]][, "mean"]
            m2 <- m2 + prob[i] * (los[[i]][, "sd"]^2 + los[[i]][, "mean"]^2)
        }
        df <- data.frame(
            mean = m1,
            sd = sqrt(pmax(.Machine$double.eps, m2 - m1^2))
        )
        if (!is.null(los[[1]]$ID)) {
            df$ID <- los[[1]]$ID
        }
        rownames(df) <- rownames(los[[1]])
        return(df)
    }

    merge.cpo <- function(cpos, prob) {
        n <- length(cpos)
        stopifnot(length(prob) == n)
        m <- length(cpos[[1]]$cpo)
        res <- matrix(0, m, 3)
        if (m > 0) {
            prob <- prob / sum(prob)
            for (i in 1:n) {
                res[, 1] <- res[, 1] + prob[i] * cpos[[i]]$cpo
                res[, 2] <- res[, 2] + prob[i] * cpos[[i]]$pit
                res[, 3] <- res[, 3] + prob[i] * cpos[[i]]$failure
            }
            res[, 3] <- as.numeric(res[, 3] > 0)
        }
        return(list(cpo = res[, 1], pit = res[, 2], failure = res[, 3]))
    }

    merge.po <- function(pos, prob) {
        n <- length(pos)
        stopifnot(length(prob) == n)
        m <- length(pos[[1]]$po)
        res <- numeric(m)
        if (m > 0) {
            prob <- prob / sum(prob)
            for (i in 1:n) {
                res <- res + prob[i] * pos[[i]]$po
            }
        }
        return(list(po = res))
    }

    stopifnot(length(prob) == length(loo))
    stopifnot(all(prob > 0))
    prob <- prob / sum(prob)
    m <- length(loo)
    res <- loo[[1]]

    verboze("Enter with prob = [", round(prob, digits = 3), "], and", m, "models", sep = " ")

    ## list
    marginals <- c(
        paste0("marginals.", c("hyperpar", "fixed", "lincomb", "lincomb.derived", "linear.predictor")),
        "internal.marginals.hyperpar"
    )
    ## list of list
    marginals2 <- paste0("marginals.", c("random", "spde2.blc", "spde3.blc"))
    ## data.frame
    summaries <- c(
        paste0("summary.", c("hyperpar", "fixed", "lincomb", "lincomb.derived", "linear.predictor")),
        "internal.summary.hyperpar"
    )
    ## list of data.frame
    summaries2 <- paste0("summary.", c("random", "spde2.blc", "spde3.blc"))
    ## items to remove
    remove <- c(
        "marginals.fitted.values", "summary.fitted.values", "dic", "waic",
        "neffp", "mode", ".args", "model.matrix"
    )
    ## items to remove in $misc
    misc.remove <- c(
        "cov.intern", "cov.intern.eigenvalues", "cov.intern.eigenvectors",
        "lincomb.derived.correlation.matrix", "lincomb.derived.covariance.matrix",
        "log.posterior.mode", "stdev.corr.negative", "stdev.corr.negative",
        "stdev.corr.positive", "theta.mode"
    )

    for (nm in marginals) {
        idx <- which(names(res) == nm)
        if (length(idx) > 0) {
            verboze("Merge '$", nm, "'")
            nm <- names(res[[idx]])
            res[[idx]] <- (inla.mclapply(
                seq_along(res[[idx]]),
                function(k) {
                    margs <- lapply(loo, function(x, kk) x[[idx]][[kk]], kk = k)
                    return(merge.marginals(margs, prob))
                },
                mc.cores = mc.cores
            ))
            names(res[[idx]]) <- nm
        }
    }

    for (nm in marginals2) {
        idx <- which(names(res) == nm)
        if (length(idx) > 0) {
            verboze("Merge '$", nm, "'")
            for (k in seq_along(res[[idx]])) {
                verboze("      '$", nm, "$", names(res[[idx]])[k], "'")
                nm <- names(res[[idx]][[k]])
                res[[idx]][[k]] <- (inla.mclapply(
                    seq_along(res[[idx]][[k]]),
                    function(kk) {
                        margs <- lapply(loo, function(x, k, kkk) x[[idx]][[k]][[kkk]], k = k, kkk = kk)
                        return(merge.marginals(margs, prob))
                    },
                    mc.cores = mc.cores
                ))
                names(res[[idx]][[k]]) <- nm
            }
        }
    }

    for (nm in summaries) {
        idx <- which(names(res) == nm)
        if (length(idx) > 0) {
            verboze("Merge '$", nm, "'")
            if (!is.null(res[[idx]]) && nrow(res[[idx]]) > 0) {
                zum <- lapply(loo, function(x) x[[idx]])
                res[[idx]] <- merge.summary(zum, prob)
            }
        }
    }

    if (!is.null(res$cpo)) {
        verboze(paste0("Merge '$cpo'"))
        nm <- "disable.inla.merge.cpo.warning"
        if (!exists(nm, envir = inla.get.inlaEnv())) {
            warning("Merging 'cpo' and 'pit'-results are/can be, approximate only")
            assign(nm, TRUE, envir = inla.get.inlaEnv())
        }
        cpo <- lapply(loo, function(x) x$cpo)
        res$cpo <- merge.cpo(cpo, prob)
    }

    if (!is.null(res$po)) {
        verboze(paste0("Merge '$po'"))
        po <- lapply(loo, function(x) x$po)
        res$po <- merge.po(po, prob)
    }

    for (nm in summaries2) {
        idx <- which(names(res) == nm)
        if (length(idx) > 0) {
            for (k in seq_along(res[[idx]])) {
                verboze(paste0("      '$", nm, "$", names(res[[idx]])[k], "'"))
                zum <- lapply(loo, function(x) x[[idx]][[k]])
                res[[idx]][[k]] <- merge.summary(zum, prob)
            }
        }
    }


    ## merge configs, if they are there
    if (!is.null(res$misc$configs)) {
        verboze("Merge '$misc$configs'")
        res$misc$configs$nconfig <- m * res$misc$configs$nconfig
        res$misc$configs$config <- as.list(seq_len(res$misc$configs$nconfig)) ## create the list to be filled
        res$misc$configs$max.log.posterior <- NA ## to be computer later
        count <- 1
        for (k in seq_along(loo)) {
            conf <- loo[[k]]$misc$configs
            for (kk in seq_len(conf$nconfig)) {
                conf$config[[kk]]$log.posterior <- conf$config[[kk]]$log.posterior +
                    conf$max.log.posterior + log(prob[k])
                conf$config[[kk]]$log.posterior.orig <- conf$config[[kk]]$log.posterior.orig +
                    conf$max.log.posterior + log(prob[k])
                res$misc$configs$config[[count]] <- conf$config[[kk]]
                count <- count + 1
            }
        }
        ## rescale the log.posterior's, similar code as in 'inla.collect.misc()'
        res$misc$configs$max.log.posterior <- max(sapply(res$misc$configs$config, function(x) x$log.posterior.orig))
        for (k in seq_len(res$misc$configs$nconfig)) {
            res$misc$configs$config[[k]]$log.posterior <- res$misc$configs$config[[k]]$log.posterior -
                res$misc$configs$max.log.posterior
            res$misc$configs$config[[k]]$log.posterior.orig <- res$misc$configs$config[[k]]$log.posterior.orig -
                res$misc$configs$max.log.posterior
        }
    }

    verboze(paste0("Merge '$misc$nfunc"))
    res$misc$nfunc <- sum(unlist(lapply(loo, function(x) x$misc$nfunc)))

    verboze(paste0("Merge '$cpu.used"))
    res$cpu.used <- rowSums(sapply(loo, function(x) x$cpu.used))

    verboze(paste0("Merge '$logfile"))
    res$logfile <- c()
    for (k in seq_along(loo)) {
        res$logfile <- c(
            res$logfile,
            "###",
            paste0("### CONFIGURATION number ", k, ", prob = ", round(prob[k], digits = 5)),
            "###",
            loo[[k]]$logfile
        )
    }

    if (!is.null(res$joint.hyper)) {
        verboze(paste0("Merge '$joint.hyper"))
        res$joint.hyper <- data.frame()
        for (k in seq_along(loo)) {
            tmp <- loo[[k]]$joint.hyper
            tmp[, ncol(tmp)] <- tmp[, ncol(tmp)] + log(prob[k])
            res$joint.hyper <- rbind(res$joint.hyper, tmp)
        }
    }

    for (nm in remove) {
        verboze(paste0("Remove '$", nm, "'"))
        idx <- which(names(res) == nm)
        if (length(idx) > 0) {
            res[[idx]] <- NULL
        }
    }

    for (nm in misc.remove) {
        verboze(paste0("Remove '$misc$", nm, "'"))
        idx <- which(names(res$misc) == nm)
        if (length(idx) > 0) {
            res$misc[[idx]] <- NULL
        }
    }

    return(res)
}
