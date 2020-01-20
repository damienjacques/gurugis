#' Add together two numbers.
#'
#' @param x A number.
#' @param z A number.
#' @return The sum of \code{x} and \code{y}.
#' @examples
#' add(1, 1)
#' add(10, 1)

my_zonal <- function(x, z, stat, digits = 0, na.rm = TRUE, ...) {
    # source: https://stat.ethz.ch/pipermail/r-sig-geo/2013-February/017475.html
    fun <- match.fun(stat)
    vals <- getValues(x)
    zones <- round(getValues(z), digits = digits)
    rDT <- data.table(vals, z = zones)
    setkey(rDT, z)
    rDT[, lapply(.SD, fun, na.rm = TRUE), by = z]
}


#' Add together two numbers.
#'
#' @param x A number.
#' @param y A number.
#' @return The sum of \code{x} and \code{y}.
#' @examples
#' zonal_pipe(1, 1)
#' zonal_pipe(10, 1)
#'


zonal_pipe <- function(zone_in, raster_in, shp_out = NULL, stat) {
    # Load raster
    r <- stack(raster_in)
    # Load zone shapefile
    shp <- readOGR(zone_in)
    # Project 'zone' shapefile into the same coordinate system than the input raster
    shp <- spTransform(shp, crs(r))
    
    # Add ID field to Shapefile
    shp@data$ID <- c(1:length(shp@data[, 1]))
    
    # Crop raster to 'zone' shapefile extent
    r <- crop(r, extent(shp))
    # Rasterize shapefile
    zone <- rasterize(shp, r, field = "ID", dataType = "INT1U")  # Change dataType if nrow(shp) > 255 to INT2U or INT4U
    
    # Zonal stats
    Zstat <- data.frame(myZonal(r, zone, stat))
    colnames(Zstat) <- c("ID", paste0(names(r), "_", c(1:(length(Zstat) - 1)), "_", stat))
    
    # Merge data in the shapefile and write it
    shp@data <- plyr::join(shp@data, Zstat, by = "ID")
    
    if (is.null(shp_out)) {
        return(shp)
    } else {
        writeOGR(shp, shp_out, layer = sub("^([^.]*).*", "\\1", basename(zone_in)), driver = "ESRI Shapefile")
    }
}
