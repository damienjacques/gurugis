
#' Fast implementation of zonal statistics
#'
#' @param x A number.
#' @param z A number.
#' @return The sum of \code{x} and \code{y}.
#' @examples
#' add(1, 1)
#' add(10, 1)
#' @export

fastzonal <- function(x, z, stats, digits = 0, na.rm = TRUE, ...) {
    # source: https://stat.ethz.ch/pipermail/r-sig-geo/2013-February/017475.html
    fun <- match.fun(stats)
    vals <- raster::getValues(x)
    zones <- round(raster::getValues(z), digits = digits)
    rDT <- data.table::data.table(vals, z = zones)
    data.table::setkey(rDT, z)
    rDT[, lapply(.SD, fun, na.rm = TRUE), by = z]
}

#' Zonal statistics using a raster and a vector zone layer
#'
#' Perform raster zonal statistics from a vector zone layer and add the results to the attribute layer of the vector layer.
#'
#' @param r A raster file for which one wishes to compute zonal statistics
#' @param z A vector layer (e.g. a shapefile) containing one polygon for each zone used to derive zonal statics (e.g. admnistrative areas)
#' @param stats The function applied on all pixels of an area (i.e. the zonal statistics)
#' @param filename The path where to write the vector layer with the result of the zonal statistics. If set to NULL returns the vector layer object (already).
#' @return A vector layer with the zonal statistics for each band of the input raster added in the attribute table
#' @examples
#' output <- zonal_pipe(precipitation, belgium, stats = "mean")
#' @export

zonal_pipe <- function(r, z, stats, filename = NULL) {
    # stack raster
    r <- raster::stack(r)

    # read vector layer
    if ("character" %in% is(z)){
        shp <- sf::st_read(z)
    }else{
        shp <- z
    }

    # projecting the vector layer in the same coordinate system as the input raster
    shp <- sf::st_transform(shp, raster::crs(r))

    # add ID field to vector layer
    shp$ID <- 1:nrow(shp)

    # crop raster to 'zone' vector layer extent
    r <- raster::crop(r, raster::extent(shp))

    # rasterize vector layer
    zone <- fasterize::fasterize(shp, raster::raster(r), field = "ID")

    # perform zonal stats
    zstat <- data.frame(fastzonal(r, zone, stats))
    colnames(zstat) <- c("ID", paste0(names(r), "_", stats))

    # merge the data into the vector layer
    shp <- merge(shp, zstat, all = T)

    # save vector layer or assign it to variable
    if (is.null(filename)) {
        return(shp)
    } else {
        sf::st_write(shp, filename)
    }
}





