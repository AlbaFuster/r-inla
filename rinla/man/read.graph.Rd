% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read.graph.R
\name{read.graph}
\alias{read.graph}
\alias{write.graph}
\alias{inla.read.graph}
\alias{inla.write.graph}
\alias{inla.graph}
\alias{summary.inla.graph}
\alias{plot.inla.graph}
\alias{print.inla.graph.summary}
\title{Read and write a graph-object}
\usage{
inla.read.graph(..., size.only = FALSE)

inla.write.graph(
  graph,
  filename = "graph.dat",
  mode = c("binary", "ascii"),
  ...
)

\method{plot}{inla.graph}(x, y, ...)

\method{summary}{inla.graph}(object, ...)

\method{print}{inla.graph.summary}(x, ...)
}
\arguments{
\item{...}{Additional arguments. In \code{inla.read.graph}, then it is the
graph definition (object, matrix, character, filename), plus extra
arguments.  In \code{inla.write.graph} it is extra arguments to
\code{inla.read.graph}.}

\item{size.only}{Only read the size of the graph}

\item{graph}{An \code{inla.graph}-object, a (sparse) symmetric matrix, a
filename containing the graph, a list or collection of characters and/or
numbers defining the graph, or a neighbours list with class \code{nb} (see
\code{spdep::card} and \code{spdep::poly2nb} for for details of \code{nb}
and an example a function returning an \code{nb} object}

\item{filename}{The filename of the graph.}

\item{mode}{The mode of the file; ascii-file or a (gzip-compressed) binary.}

\item{x}{An \code{inla.graph} -object}

\item{y}{Not used}

\item{object}{An \code{inla.graph} -object}
}
\value{
The output of \code{inla.read.graph}, is an \code{inla.graph}
object, with elements \item{n}{is the size of the graph} \item{nnbs}{is a
vector with the number of neigbours} \item{nbs}{is a list-list with the
neigbours} \item{cc}{list with connected component information \itemize{
\item\code{id}is a vector with the connected component id for each node
(starting from 1) \item\code{n}is the number of connected components
\item\code{nodes}is a list-list of nodes belonging to each connected
component \item\code{mean}is a factor with one level for each connected
component of size larger than one, otherwise \code{NA} } } Methods
implemented for \code{inla.graph} are \code{summary} and \code{plot}.  The
method \code{plot} require the libraries \code{Rgraphviz} and \code{graph}
from the Bioconductor-project, see \url{https://www.bioconductor.org}.
}
\description{
Construct a graph-object from a file or a matrix; write graph-object to file
}
\examples{

## a graph from a file
g.file1 <- tempfile() # E.g. "g.dat"
cat("3 1 1 2 2 1 1 3 0\n", file = g.file1)
g = inla.read.graph(g.file1)
## writing an inla.graph-object to file
g.file2 = inla.write.graph(g, mode="binary", filename = tempfile())
## re-reading it from that file
gg = inla.read.graph(g.file2)
summary(g)
summary(gg)

\dontrun{
plot(g)
inla.spy(g)
## when defining the graph directly in the call,
## we can use a mix of character and numbers
g = inla.read.graph(c(3, 1, "1 2 2 1 1 3", 0))
inla.spy(c(3, 1, "1 2 2 1 1 3 0"))
inla.spy(c(3, 1, "1 2 2 1 1 3 0"),  reordering=3:1)
inla.write.graph(c(3, 1, "1 2 2 1 1 3 0"))

## building a graph from adjacency matrix
adjacent = matrix(0, nrow = 4, ncol = 4)
adjacent[1,4] = adjacent[4,1] = 1
adjacent[2,4] = adjacent[4,2] = 1
adjacent[2,3] = adjacent[3,2] = 1
adjacent[3,4] = adjacent[4,3] = 1
g = inla.read.graph(adjacent)
plot(g)
summary(g)
}

}
\seealso{
\code{\link[=inla.spy]{inla.spy()}}
}
\author{
Havard Rue \email{hrue@r-inla.org}
}
