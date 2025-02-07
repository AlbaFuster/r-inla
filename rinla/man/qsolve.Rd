% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qsolve.R
\name{qsolve}
\alias{qsolve}
\alias{inla.qsolve}
\title{Solves linear SPD systems}
\usage{
inla.qsolve(
  Q,
  B,
  reordering = inla.reorderings(),
  method = c("solve", "forward", "backward")
)
}
\arguments{
\item{Q}{A SPD matrix, either as a (dense) matrix or sparse-matrix}

\item{B}{The right hand side matrix, either as a (dense) matrix or
sparse-matrix.}

\item{reordering}{The type of reordering algorithm to be used for
\code{TAUCS}; either one of the names listed in \code{inla.reorderings()} or
the output from \code{inla.qreordering(Q)}.  The default is "auto" which try
several reordering algorithm and use the best one for this particular matrix
(using the TAUCS library).}

\item{method}{The system to solve, one of \code{"solve"}, \code{"forward"}
or \code{"backward"}. Let \verb{Q = L L^T}, where \code{L} is lower
triangular (the Cholesky triangle), then \code{method="solve"} solves
\verb{L L^T X = B} or equivalently \verb{Q X = B}, \code{method="forward"}
solves \verb{L X = B}, and \code{method="backward"} solves \verb{L^T X = B}.}
}
\value{
\code{inla.qsolve} returns a matrix \code{X}, which is the solution
of \verb{Q X = B}, \verb{L X = B} or \verb{L^T X = B} depending on the value
of \code{method}.
}
\description{
This routine use the GMRFLib implementation to solve linear systems with a
SPD matrix.
}
\examples{

 n = 10
 nb <- n-1
 QQ = matrix(rnorm(n^2), n, n)
 QQ <- QQ \%*\% t(QQ)

 Q = inla.as.sparse(QQ)
 B = matrix(rnorm(n*nb), n, nb)

 X = inla.qsolve(Q, B, method = "solve")
 XX = inla.qsolve(Q, B, method = "solve", reordering = inla.qreordering(Q))
 print(paste("err solve1", sum(abs( Q \%*\% X - B))))
 print(paste("err solve2", sum(abs( Q \%*\% XX - B))))

 ## the forward and backward solve is tricky, as after permutation and with Q=LL', then L is
 ## lower triangular, but L in the orginal ordering is not lower triangular. if the rhs is iid
 ## noise, this is not important. to control the reordering, then the 'taucs' library must be
 ## used.
 inla.setOption(smtp = 'taucs')

 ## case 1. use the matrix as is, no reordering
 r <- "identity"
 L = t(chol(Q))
 X = inla.qsolve(Q, B, method = "forward", reordering = r)
 XX = inla.qsolve(Q, B, method = "backward", reordering = r)
 print(paste("err forward ", sum(abs(L \%*\% X - B))))
 print(paste("err backward", sum(abs(t(L) \%*\% XX - B))))

 ## case 2. use a reordering from the library
 r <- inla.qreordering(Q)
 im <- r$ireordering
 m <- r$reordering
 print(cbind(idx = 1:n, m, im) )
 Qr <- Q[im, im]
 L = t(chol(Qr))[m, m]

 X = inla.qsolve(Q, B, method = "forward", reordering = r)
 XX = inla.qsolve(Q, B, method = "backward", reordering = r)
 print(paste("err forward ", sum(abs( L \%*\% X - B))))
 print(paste("err backward", sum(abs( t(L) \%*\% XX - B))))

}
\author{
Havard Rue \email{hrue@r-inla.org}
}
