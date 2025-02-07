% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spmesh.R
\name{inla.spTransform}
\alias{inla.spTransform}
\title{Wrapper method for \code{fmesher::fm_transform}}
\usage{
inla.spTransform(x, CRSobj, ...)
}
\arguments{
\item{x}{The object that should be transformed from it's current CRS to a
new CRS}

\item{CRSobj}{passed on as the \code{crs} argument to \code{\link[fmesher:fm_transform]{fmesher::fm_transform()}}.}

\item{\dots}{Potential other arguments for \code{\link[fmesher:fm_transform]{fmesher::fm_transform()}}.}
}
\value{
The object is returned with its coordinates transformed
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} in favour of \code{\link[fmesher:fm_transform]{fmesher::fm_transform()}}.
Handles transformation of various inla objects according to coordinate
reference systems of \code{sf::crs}, \code{sp::CRS} or \code{inla.CRS} class.
}
\examples{

if (require("sf") && require("sp") && require("fmesher")) {
    latt <- inla.mesh.lattice(-10:10, 40:60)
    mesh1 <- inla.mesh.create(
        lattice = latt, extend = FALSE, refine = FALSE,
        crs = fm_CRS("longlat_norm")
    )
    mesh2 <- fm_transform(mesh1, fm_crs("lambert_globe"))
    print(summary(mesh1))
    print(summary(mesh2))
}
}
\seealso{
\code{\link[=inla.CRS]{inla.CRS()}}
}
\author{
Finn Lindgren \href{mailto:finn.lindgren@gmail.com}{finn.lindgren@gmail.com}
}
