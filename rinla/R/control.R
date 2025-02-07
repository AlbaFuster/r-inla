#' @title inla control argument handlers
#' @description
#' Methods for controlling [inla()] and [f()] `control` arguments
#' 
#' @name inla-control
#' @rdname inla-control
#' @keywords internal
#' @export
ctrl_class <- function(x) {
    cl <- class(x)
    i <- grep("^ctrl_", cl)
    if (length(i) == 0) {
        return(NA_character_)
    }
    cl[min(i)]
}

#' @describeIn inla-control Returns the type-part of the control class name, i.e.
#' without the "ctrl_" prefix.
#' @export
ctrl_type <- function(x) {
    UseMethod("ctrl_type")
}

#' @rdname inla-control
#' @export
ctrl_type.default <- function(x) {
    sub("^ctrl_", replacement = "", x = ctrl_class(x))
}

#' @rdname inla-control
#' @export
ctrl_type.character <- function(x) {
    sub("^ctrl_|^control\\.", replacement = "", x = x)
}

#' @describeIn inla-control Checks that the elements are named and match
#' the available ones in the corresponding default control object.
#' @param data An optional data object (`data.frame`, `list`, or `environment`,
#' see the `what` argument of [base:attach()]).
#' @param .envir The enclosing parent frame for resolving variables in `x`
#' @export
ctrl_check <- function(x, the_type, default = NULL) {
    x_type <- ctrl_type(x)
    if (!is.na(x_type) && !identical(x_type, the_type)) {
        stop(
            paste0(
                "Control object type mismatch. Expected a plain list() or a `ctrl_",
                the_type,
                "` object, but received a `",
                ctrl_class(x),
                "`."
            )
        )
    }
    
    if (length(x) == 0) {
        return(x)
    }
    
    if (is.null(default)) {
        default <- ctrl_default(the_type)
    }
    def_names <- names(default)
    x_names <- names(x)
    
    if (is.null(x_names)) {
        stop(paste0(
            "Elements in control-argument `control.", the_type, "' must be named.",
            "\n  Valid names are:\n",
            paste0(
                strwrap(paste0(sort(def_names), collapse = ", "),
                        prefix = "\t"),
                collapse = "\n"
            )))
    }
    
    if (any(!(x_names %in% def_names))) {
        warning(paste0("Control name(s) ", paste0(
                                               "'",
                                               x_names[!(x_names %in% def_names)],
                                               "'",
                                               collapse = ", "
                                           ), " appears to be invalid for `control.", the_type, "` and will be removed.",
                       "\n  Valid names are:\n",
                       paste0(
                           strwrap(paste0(sort(def_names), collapse = ", "),
                                   prefix = "\t"),
                           collapse = "\n"
                       )),
                immediate. = TRUE)
    }
    x_names <- intersect(x_names, def_names)
    x <- x[x_names]

                                        # Handle sub-controls
    sub.controls <- x_names[grep(pattern = "^control\\.", x = x_names)]
    for (nm in sub.controls) {
        nm_type <- ctrl_type(nm)
        if (!is.null(x[[nm]])) {
            x[[nm]] <- ctrl_object(x[[nm]], nm_type)
        }
    }

    return(x)
}

#' @describeIn inla-control Construct a control object and check that it's compatible
#' with the corresponding defaults.
#' @param check logical; If `TRUE` (default), calls `ctrl_check()` to verify
#' compliance with the default object of the target control type. Must be set
#' to `FALSE` by code calling `ctrl_object()` to construct default objects.
#' @export
ctrl_object <- function(x, the_type, data = NULL, check = TRUE) {
    x <- local({
        env_name <- paste0("inla.tmp.env", as.character(runif(1)))
        attach(data, name = env_name, warn.conflicts = FALSE)
        xyzzy_xyzzy <- x
        detach(env_name, character.only = TRUE)
        xyzzy_xyzzy
    })
    if (check) {
        x <- ctrl_check(x = x, the_type = the_type)
    }
    structure(
        if (is.null(x)) list() else x,
        class = c(paste0("ctrl_", the_type),
                  "inla_ctrl_object"
                  )
    )
}

#' @rdname inla-control
#' @export
ctrl_default <- function(x) {
    UseMethod("ctrl_default")
}

ctrl_default_call <- function(x) {
    if (grepl("^ctrl_", x = x)) {
                                        # When x is a ctrl_ class name
        the_call <- sub(pattern = "^ctrl_", replacement = "control.", x = x)
    } else {
                                        # When x is a ctrl_ type
        the_call <- paste0("control.", x)
    }
    the_call <- gsub(pattern = "_", replacement = ".", x = the_call)
    the_call
}

#' @rdname inla-control
#' @export
ctrl_default.character <- function(x) {
    do.call(ctrl_default_call(x), list())
}

#' @rdname inla-control
#' @export
ctrl_default.inla_ctrl_object <- function(x) {
    do.call(ctrl_default_call(ctrl_class(x)), list())
}

#' @rdname inla-control
#' @export
ctrl_update <- function(x, ...) {
    UseMethod("ctrl_update")
}

#' @describeIn inla-control Merges the `x` object with the defaults for control
#' type `ctrl_type(x)`. Recursively handles `control.*` elements, with `NULL`
#' defaults also being replaced by their corresponding defaults before merging.
#' @param default A default object of matching `ctrl_*` class.
#' If `NULL`, uses `ctrl_default(x)` instead.
#' @export
ctrl_update.inla_ctrl_object <- function(x, ..., default = NULL) {
    if (is.null(default)) {
        default <- ctrl_default(x)
    }
    x <- ctrl_check(x, the_type = ctrl_type(x), default = default)
    def_names <- names(default)
    x_names <- names(x)
    x_names <- intersect(x_names, def_names)

                                        # Handle sub-controls
    sub.controls <- def_names[grep(pattern = "^control\\.", x = def_names)]
    for (nm in sub.controls) {
        nm_type <- ctrl_type(nm)
        if (nm %in% x_names) {
            default[nm] <- x[nm]
        }
        if (!is.null(default[[nm]])) {
            default[[nm]] <- ctrl_update(default[[nm]])
        }
    }
                                        # Copy over everything else
    copy_names <- setdiff(x_names, sub.controls)
    default[copy_names] <- x[copy_names]

    default
}

ctrl_handle_hyper <- function(x, model, section) {
    x$hyper <- inla.set.hyper(
        model,
        section,
        x[["hyper"]],
        x[["initial"]],
        x[["fixed"]],
        x[["prior"]],
        x[["param"]]
    )
    x
}

#' @rdname inla-control
#' @param model character; a model specifier
#' @export
ctrl_update.ctrl_family <- function(x, ..., model) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, model = model, section = "likelihood")
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_mix <- function(x, ...) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, y[["model"]], "mix")
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_link <- function(x, ...) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, y[["model"]], "link")
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_lp_scale <- function(x, ...) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, "lp.scale", "lp.scale")
    y
}

#' @describeIn inla-control Requires `control.compute` and `control.inla` to be provided,
#' in order to determine if `compute` needs to be forced to `TRUE`. To ignore,
#' use `ctrl_update(x, control.compute = list(), control.inla = list())`.
#' @param control.compute A `ctrl_compute` object.
#' @param control.inla A `ctrl_inla` object.
#' @export
ctrl_update.ctrl_predictor <- function(x, ..., control.compute, control.inla) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, "predictor", "predictor")
    if (isTRUE(control.compute[["cpo"]]) ||
        isTRUE(control.compute[["dic"]]) ||
        isTRUE(control.compute[["po"]]) ||
        isTRUE(control.compute[["waic"]]) ||
        isTRUE(control.compute[["control.gcpo"]][["enable"]]) ||
        !is.null(y[["link"]]) ||
        (is.character(control.inla[["control.vb"]][["enable"]]) ||
         isTRUE(control.inla[["control.vb"]][["enable"]]))) {
        y$compute <- TRUE
    }
    y
}

#' @describeIn inla-control If `residuals` is `TRUE`, also sets `dic = TRUE`.
#' @export
ctrl_update.ctrl_compute <- function(x, ...) {
    y <- NextMethod()
    if (isTRUE(y[["residuals"]])) {
        y$dic <- TRUE
    }
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_group <- function(x, ...) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, y[["model"]], "group")
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_scopy <- function(x, ...) {
    y <- NextMethod()
    ##y <- ctrl_handle_hyper(y, y[["model"]], "latent")
    y <- ctrl_handle_hyper(y, "scopy", "latent")
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_hazard <- function(x, ...) {
    y <- NextMethod()
    y <- ctrl_handle_hyper(y, y[["model"]], "hazard")
    y
}

#' @rdname inla-control
#' @export
ctrl_update.ctrl_mode <- function(x, ...) {
    y <- NextMethod()
    if (!is.null(y[["result"]]) &&
        !(is.character(y$result) && file.exists(y$result))) {
        ## Reduce the size of 'result' stored in 'r$.args'. If this is stored directly it
        ## can/will require lots of storage. We do this by creating a stripped object with only
        ## what is needed and pass that one along, with the expected classical contents.
        ## Assign the "inla" class, in case there are checks on the class.
        y[["result"]] <-
            structure(list(mode = list(x = y[["result"]][["mode"]][["x"]],
                                       theta = y[["result"]][["mode"]][["theta"]])),
                      class = "inla")
    }
    y
}
