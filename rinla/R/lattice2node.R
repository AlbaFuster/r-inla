#' Functions to define mapping between a lattice and nodes
#' 
#' These functions define mapping in between two-dimensional indices on a
#' lattice and the one-dimensional node representation used in `inla`.
#' 
#' The mapping from node to lattice follows the default `R` behaviour
#' (which is column based storage), and `as.vector(A)` and `matrix(a,
#' nrow, ncol)` can be used instead of `inla.matrix2vector` and
#' `inla.vector2matrix`.
#' 
#' 
#' @aliases lattice2node inla.lattice2node node2lattice inla.node2lattice
#' node2lattice.mapping inla.node2lattice.mapping lattice2node.mapping
#' inla.lattice2node.mapping matrix2vector vector2matrix inla.matrix2vector
#' inla.vector2matrix
#' @param nrow Number of rows in the lattice.
#' @param ncol Number of columns in the lattice.
#' @param irow Lattice row index, between `1` and `nrow`
#' @param icol Lattice column index, between `1` and `ncol`
#' @param node The node index, between `1` and `ncol*nrow`
#' @param a.matrix is a matrix to be mapped to a vector using internal
#' representation defined by `inla.lattice2node`
#' @param a.vector is a vector to be mapped into a matrix using the internal
#' representation defined by `inla.node2lattice`
#' @return `inla.lattice2node.mapping` returns the hole mapping as a
#' matrix, and `inla.node2lattice.mapping` returns the hole mapping as
#' `list(irow=..., icol=...)`. `inla.lattice2node` and
#' `inla.node2lattice` provide the mapping for a given set of lattice
#' indices and nodes. `inla.matrix2vector` provide the mapped vector from
#' a matrix, and `inla.vector2matrix` provide the inverse mapped matrix
#' from vector.
#' @author Havard Rue \email{hrue@@r-inla.org}
#' @seealso [inla]
#' @examples
#' 
#' ## write out the mapping using the two alternatives
#' nrow = 2
#' ncol = 3
#' mapping = inla.lattice2node.mapping(nrow,ncol)
#' 
#' for (i in 1:nrow){
#'     for(j in 1:ncol){
#'         print(paste("Alt.1: lattice index [", i,",", j,"] corresponds",
#'                     "to node [", mapping[i,j],"]", sep=""))
#'     }
#' }
#' 
#' for (i in 1:nrow){
#'     for(j in 1:ncol){
#'         print(paste("Alt.2: lattice index [", i,",", j,"] corresponds to node [",
#'                     inla.lattice2node(i,j,nrow,ncol), "]", sep=""))
#'     }
#' }
#' 
#' inv.mapping = inla.node2lattice.mapping(nrow,ncol)
#' for(node in 1:(nrow*ncol))
#'    print(paste("Alt.1: node [", node, "] corresponds to lattice index [",
#'                inv.mapping$irow[node], ",",
#'                inv.mapping$icol[node],"]", sep=""))
#' 
#' for(node in 1:(nrow*ncol))
#'    print(paste("Alt.2: node [", node, "] corresponds to lattice index [",
#'                inla.node2lattice(node,nrow,ncol)$irow[1], ",",
#'                inla.node2lattice(node,nrow,ncol)$icol[1],"]", sep=""))
#' 
#' ## apply the mapping from matrix to vector and back
#' n = nrow*ncol
#' z = matrix(1:n,nrow,ncol)
#' z.vector = inla.matrix2vector(z)  # as.vector(z) could also be used
#' print(mapping)
#' print(z)
#' print(z.vector)
#' 
#' ## the vector2matrix is the inverse, and should give us the z-matrix
#' ## back. matrix(z.vector, nrow, ncol) could also be used here.
#' z.matrix = inla.vector2matrix(z.vector, nrow, ncol)
#' print(z.matrix)
#' 
#' @name lattice2node
#' @rdname lattice2node
NULL




#' @rdname lattice2node
#' @export
`inla.lattice2node.mapping` <- function(nrow, ncol) {
    ## return a matrix with the mapping

    stopifnot(nrow > 0 && ncol > 0)

    mapping <- matrix(NA, nrow = nrow, ncol = ncol)
    for (i in 1:nrow) {
        j <- 1:ncol
        mapping[i, j] <- inla.lattice2node(i, j, nrow, ncol)
    }
    return(mapping)
}

#' @rdname lattice2node
#' @export
`inla.node2lattice.mapping` <- function(nrow, ncol) {
    stopifnot(nrow > 0 && ncol > 0)

    return(inla.node2lattice(1:(nrow * ncol), nrow, ncol))
}

#' @rdname lattice2node
#' @export
`inla.lattice2node` <- function(irow, icol, nrow, ncol) {
    ## convert from a lattice point (irow, icol) to a node-number in
    ## the graph; similar to the GMRFLib_lattice2node()-function in
    ## GMRFLib.  Indices goes from irow=1...nrow, to icol=1...ncol and
    ## node=1.....nrow*ncol.

    stopifnot(nrow > 0 && ncol > 0)

    if (length(irow) == length(icol) && length(irow) > 1) {
        ## this makes it kind of 'vectorize' for two arguments...
        n <- length(irow)
        k <- 1:n
        return(sapply(k,
            function(irow, icol, nrow, ncol, k) {
                return(inla.lattice2node(irow[k], icol[k], nrow, ncol))
            },
            irow = irow, icol = icol, nrow = nrow, ncol = ncol
        ))
    } else {
        return((irow - 1) + (icol - 1) * nrow + 1)
    }
}

#' @rdname lattice2node
#' @export
`inla.node2lattice` <- function(node, nrow, ncol) {
    ## convert from a node-number in the graph to a lattice point
    ## (irow, icol); similar to the GMRFLib_node2lattice()-function in
    ## GMRFLib.  Indices goes from irow=1...nrow, to icol=1...ncol and
    ## node=1.....nrow*ncol.

    stopifnot(nrow > 0 && ncol > 0)

    icol <- (node - 1) %/% nrow
    irow <- (node - 1) %% nrow

    return(list(irow = irow + 1, icol = icol + 1))
}

#' @rdname lattice2node
#' @export
`inla.matrix2vector` <- function(a.matrix) {
    ## utility function for mapping a matrix to inla's internal `node'
    ## representation by inla.lattice2node() and inla.node2lattice()

    if (!is.matrix(a.matrix)) {
          stop("Argument must be a matrix")
      }

    return(as.vector(a.matrix))
}
#' @rdname lattice2node
#' @export
`inla.vector2matrix` <- function(a.vector, nrow, ncol) {
    ## utility function for mapping from inla's internal `node'
    ## representation, inla.lattice2node() and inla.node2lattice(),
    ## and to a matrix

    n <- length(a.vector)
    if (missing(nrow) && !missing(ncol)) {
          nrow <- n %/% ncol
      }
    if (!missing(nrow) && missing(ncol)) {
          ncol <- n %/% nrow
      }
    if (n != nrow * ncol) {
          stop(paste("Length of vector", n, "does not equal to nrow*ncol", nrow * ncol))
      }

    return(matrix(a.vector, nrow, ncol))
}
