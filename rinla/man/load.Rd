% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/load.R
\name{inla.load}
\alias{inla.load}
\title{Load or source a file}
\usage{
inla.load(filename, debug = TRUE)
}
\arguments{
\item{filename}{The name of the file to be loaded, alternatively, sourced.}

\item{debug}{Logical. Turn on/off debug information.}
}
\value{
None
}
\description{
Load or source a file: (internal use)
}
\details{
Try to \code{load} the file into the global environment, if that fail, try
to \code{source} the file into the global environment.
}
\author{
Havard Rue \email{hrue@r-inla.org}
}
\keyword{internal}
