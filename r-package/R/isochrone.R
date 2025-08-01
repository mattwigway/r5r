#' Estimate isochrones from a given location
#'
#' @description Fast computation of isochrones from a given location. The
#' function can return either polygon-based or line-based isochrones.
#' Polygon-based isochrones are generated as concave polygons based on the
#' travel times from the trip origin to all nodes in the transport network.
#' Meanwhile, line-based isochronesare based on travel times from each origin
#' to the centroids of all segments in the transport network.
#'
#' @template r5r_network
#' @template r5r_core
#' @param origins Either a `POINT sf` object with WGS84 CRS, or a
#'        `data.frame` containing the columns `id`, `lon` and `lat`.
#' @param cutoffs numeric vector. Number of minutes to define the time span of
#'        each Isochrone. Defaults to `c(0, 15, 30)`.
#' @param sample_size numeric. Sample size of nodes in the transport network used
#'        to estimate isochrones. Defaults to `0.8` (80% of all nodes in the
#'        transport network). Value can range between `0.2` and `1`. Smaller
#'        values increase computation speed but return results with lower
#'        precision. This parameter has no effect when `polygon_output = FALSE`.
#' @param mode A character vector. The transport modes allowed for access,
#'        transfer and vehicle legs of the trips. Defaults to `WALK`. Please see
#'        details for other options.
#' @param mode_egress A character vector. The transport mode used after egress
#'        from the last public transport. It can be either `WALK`, `BICYCLE` or
#'        `CAR`. Defaults to `WALK`. Ignored when public transport is not used.
#' @param departure_datetime A POSIXct object. Please note that the departure
#'        time only influences public transport legs. When working with public
#'        transport networks, please check the `calendar.txt` within your GTFS
#'        feeds for valid dates. Please see details for further information on
#'        how datetimes are parsed.
#' @param polygon_output A Logical. If `TRUE`, the function outputs
#'        polygon-based isochrones (the default) based on travel times from each
#'        origin to a sample of a random  sample nodes in the transport network
#'        (see parameter `sample_size`). If `FALSE`, the function outputs
#'        line-based isochrones based on travel times from each origin to the
#'        centroids of all segments in the transport network.
#' @param time_window An integer. The time window in minutes for which `r5r`
#'        will calculate multiple travel time matrices departing each minute.
#'        Defaults to 10 minutes. The function returns the result based on
#'        median travel times. Please read the time window vignette for more
#'        details on its usage `vignette("time_window", package = "r5r")`
#' @param max_walk_time An integer. The maximum walking time (in minutes) to
#'        access and egress the transit network, or to make transfers within the
#'        network. Defaults to no restrictions, as long as `max_trip_duration`
#'        is respected. The max time is considered separately for each leg (e.g.
#'        if you set `max_walk_time` to 15, you could potentially walk up to 15
#'        minutes to reach transit, and up to _another_ 15 minutes to reach the
#'        destination after leaving transit). Defaults to `Inf`, no limit.
#' @param max_bike_time An integer. The maximum cycling time (in minutes) to
#'        access and egress the transit network. Defaults to no restrictions, as
#'        long as `max_trip_duration` is respected. The max time is considered
#'        separately for each leg (e.g. if you set `max_bike_time` to 15 minutes,
#'        you could potentially cycle up to 15 minutes to reach transit, and up
#'        to _another_ 15 minutes to reach the destination after leaving
#'        transit). Defaults to `Inf`, no limit.
#' @param max_car_time An integer. The maximum driving time (in minutes) to
#'        access and egress the transit network. Defaults to no restrictions, as
#'        long as `max_trip_duration` is respected. The max time is considered
#'        separately for each leg (e.g. if you set `max_car_time` to 15 minutes,
#'        you could potentially drive up to 15 minutes to reach transit, and up
#'        to _another_ 15 minutes to reach the destination after leaving transit).
#'        Defaults to `Inf`, no limit.
#' @param max_trip_duration An integer. The maximum trip duration in minutes.
#'        Defaults to 120 minutes (2 hours).
#' @param walk_speed A numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed A numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides An integer. The maximum number of public transport rides
#'        allowed in the same trip. Defaults to 3.
#' @param max_lts An integer between 1 and 4. The maximum level of traffic
#'        stress that cyclists will tolerate. A value of 1 means cyclists will
#'        only travel through the quietest streets, while a value of 4 indicates
#'        cyclists can travel through any road. Defaults to 2. Please see
#'        details for more information.
#' @template draws_per_minute
#' @param n_threads An integer. The number of threads to use when running the
#'        router in parallel. Defaults to use all available threads (`Inf`).
#' @param progress A logical. Whether to show a progress counter when running
#'        the router. Defaults to `FALSE`. Only works when `verbose` is set to
#'        `FALSE`, so the progress counter does not interfere with `R5`'s output
#'        messages. Setting `progress` to `TRUE` may impose a small penalty for
#'        computation efficiency, because the progress counter must be
#'        synchronized among all active threads.
#' @template verbose
#'
#' @return A `"sf" "data.frame"` for each isochrone of each origin.
#'
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template raptor_algorithm_section
#'
#' @family Isochrone
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' options(java.parameters = "-Xmx2G")
#' library(r5r)
#' library(ggplot2)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_network <- build_network(data_path = data_path)
#'
#' # load origin/point of interest
#' points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
#' origin <- points[2,]
#'
#' departure_datetime <- as.POSIXct(
#'  "13-05-2019 14:00:00",
#'  format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#' # estimate polygon-based isochrone from origin
#' iso_poly <- isochrone(
#'   r5r_network,
#'   origins = origin,
#'   mode = "walk",
#'   polygon_output = TRUE,
#'   departure_datetime = departure_datetime,
#'   cutoffs = seq(0, 120, 30)
#'   )
#'
#' head(iso_poly)
#'
#'
#' # estimate line-based isochrone from origin
#' iso_lines <- isochrone(
#'   r5r_network,
#'   origins = origin,
#'   mode = "walk",
#'   polygon_output = FALSE,
#'   departure_datetime = departure_datetime,
#'   cutoffs = seq(0, 100, 25)
#'   )
#'
#' head(iso_lines)
#'
#'
#' # plot colors
#' colors <- c('#ffe0a5','#ffcb69','#ffa600','#ff7c43','#f95d6a',
#'             '#d45087','#a05195','#665191','#2f4b7c','#003f5c')
#'
#' # polygons
#' ggplot() +
#'   geom_sf(data=iso_poly, aes(fill=factor(isochrone))) +
#'   scale_fill_manual(values = colors) +
#'   theme_minimal()
#'
#' # lines
#' ggplot() +
#'   geom_sf(data=iso_lines, aes(color=factor(isochrone))) +
#'   scale_color_manual(values = colors) +
#'   theme_minimal()
#'
#' stop_r5(r5r_network)
#'
#' @export
isochrone <- function(r5r_network,
                      r5r_core = deprecated(),
                      origins,
                      mode = "transit",
                      mode_egress = "walk",
                      cutoffs = c(0, 15, 30),
                      sample_size = 0.8,
                      departure_datetime = Sys.time(),
                      polygon_output = TRUE,
                      time_window = 10L,
                      max_walk_time = Inf,
                      max_bike_time = Inf,
                      max_car_time = Inf,
                      max_trip_duration = 120L,
                      walk_speed = 3.6,
                      bike_speed = 12,
                      max_rides = 3,
                      max_lts = 2,
                      draws_per_minute = 5L,
                      n_threads = Inf,
                      verbose = FALSE,
                      progress = TRUE,
                      zoom = 10){


  # deprecating r5r_core --------------------------------------
  if (lifecycle::is_present(r5r_core)) {

    cli::cli_warn(c(
      "!" = "The `r5r_core` argument is deprecated as of r5r v2.3.0.",
      "i" = "Please use the `r5r_network` argument instead."
    ))

    r5r_network <- r5r_core
  }

# check inputs ------------------------------------------------------------
  checkmate::assert_class(r5r_network, "r5r_network")

  # check cutoffs
  checkmate::assert_numeric(cutoffs, lower = 0)
  checkmate::assert_logical(polygon_output)

  # check sample_size
  checkmate::assert_numeric(sample_size, lower = 0.2, upper = 1, max.len = 1)

  # max cutoff is used as max_trip_duration
  # for isolines to work we need to have some values that are above the contour line so it can interpolate, so
  # don't set a max trip duration based on cutoffs.
  #max_trip_duration = as.integer(max(cutoffs))

  # sort cutoffs and include 0
  if (min(cutoffs) > 0) {cutoffs <- sort(c(0, cutoffs))}


# IF no destinations input ------------------------------------------------------------


  ## whether polygon- or line-based isochrones
  if (isTRUE(polygon_output)) {
    bbox = r5r_network@jcore$getBoundingBox()

    minlon = bbox[[1]]
    minlat = bbox[[2]]
    maxlon = bbox[[3]]
    maxlat = bbox[[4]]

    # for a polygon isochrone we use a web mercator regular grid (a la conveyal).
    # https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Example:_Convert_a_GPS_coordinate_to_a_pixel_position_in_a_Web_Mercator_tile
    minx = floor(lon_to_webmercator_pixel(minlon, zoom))
    maxx = ceiling(lon_to_webmercator_pixel(maxlon, zoom))
    # y points south in web mercator
    miny = floor(lat_to_webmercator_pixel(maxlat, zoom))
    maxy = ceiling(lat_to_webmercator_pixel(minlat, zoom))

    destinations = data.frame(
      # cartesian product of x and y
      id = as.character(1:((maxx - minx + 1) * (maxy - miny + 1))),
      x = rep(minx:maxx, each=length(miny:maxy)),
      y = rep(miny:maxy, times=length(minx:maxx))
    )

    destinations$lat = webmercator_pixel_to_lat(destinations$y, zoom)
    destinations$lon = webmercator_pixel_to_lon(destinations$x, zoom)
  }

  if(isFALSE(polygon_output)){

    network_e <- r5r::street_network_to_sf(r5r_network)$edges

    destinations <- sf::st_centroid(network_e)
    }

  # rename id col
  names(destinations)[1] <- 'id'
  destinations$id <- as.character(destinations$id)


    # estimate travel time matrix
    ttm <- travel_time_matrix(r5r_network = r5r_network,
                              origins = origins,
                              destinations = destinations,
                              mode = mode,
                              mode_egress = mode_egress,
                              departure_datetime = departure_datetime,
                              time_window = time_window,
                              # percentiles = percentiles,
                              max_walk_time = max_walk_time,
                              max_bike_time = max_bike_time,
                              max_car_time = max_car_time,
                              max_trip_duration = 120L,
                              walk_speed = walk_speed,
                              bike_speed = bike_speed,
                              max_rides = max_rides,
                              max_lts = max_lts,
                              draws_per_minute = draws_per_minute,
                              n_threads = n_threads,
                              verbose = verbose,
                              progress = progress
                              )

    if (isFALSE(polygon_output)) {
      # polygon output works on raw ttm, only aggregate for line output
      # ignore travel times equal to 0
      ttm <- ttm[travel_time_p50>0, ]

      # aggregate travel-times
      # ttm[, isochrone_interval := cut(x=travel_time_p50, breaks=cutoffs)]
      ttm[, isochrone := cut(x=travel_time_p50, breaks=cutoffs, labels=F)]
      ttm[, isochrone := cutoffs[cutoffs>0][isochrone]]
    }


    ### fun to get isochrones for each origin
    # polygon-based isochrones
      prep_iso_poly <- function(orig){ # orig = '89a90128107ffff'

      temp_ttm <- subset(ttm, from_id == orig)[destinations, on = c(to_id = "id"), nomatch=NA]

      checkmate::assert_true(nrow(temp_ttm) == nrow(destinations))

      # turn the travel time matrix into an actual R matrix
      # this would probably be hugely more efficient if we just used a WebMercatorGridPointSet on the R5
      # side and returned a double array.
      # TODO make sure still sorted?
      mtx = matrix(temp_ttm$travel_time_p50, (maxy - miny + 1), (maxx - minx + 1))

      nonzero_cutoffs = cutoffs[cutoffs>0]
      # create the bands
      bands = isoband::isobands(minx:maxx, miny:maxy, mtx, rep(0, length(nonzero_cutoffs)), nonzero_cutoffs)

      # convert back to lat lon
      bands = map(bands, function (b) {
        b$x = webmercator_pixel_to_lon(b$x, zoom)
        b$y = webmercator_pixel_to_lat(b$y, zoom)
        return(b)
      })
      class(bands) <- c("isobands", "iso")
      
      iso = data.table::data.table(sf::st_sf(
        id=orig,
        isochrone=nonzero_cutoffs,
        geometry=sf::st_make_valid(sf::st_sfc(isoband::iso_to_sfg(bands), crs=4326))
      ))

      iso <- iso[ order(-isochrone), ]
      data.table::setcolorder(iso, c('id', 'isochrone'))
      # iso <- sf::st_as_sf(iso)
      # plot(iso)
      return(iso)
    }


    # line-based isochrones
      prep_iso_lines <- function(orig){ # orig = '89a90128107ffff'

        temp_ttm <- subset(ttm, from_id == orig)

        # join ttm results to destinations
        temp_iso <- subset(network_e, edge_index %in% temp_ttm$to_id)
        data.table::setDT(temp_iso)[, edge_index := as.character(edge_index)]
        temp_iso[temp_ttm, on=c('edge_index' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]
       # temp_iso <- sf::st_as_sf(temp_iso)

      temp_iso <- temp_iso[order(-isochrone, -travel_time_p50)]
      data.table::setcolorder(temp_iso, c('edge_index', 'osm_id', 'isochrone', 'travel_time_p50'))
      # plot(temp_iso)
      return(temp_iso)
    }

    # get the isocrhone from each origin
    prep_iso <- ifelse(isTRUE(polygon_output), prep_iso_poly, prep_iso_lines)
    iso_list <- lapply(X = unique(origins$id), FUN = prep_iso)

    # put output together
    iso <- data.table::rbindlist(iso_list)
    iso <- sf::st_sf(iso)
    iso <- subset(iso, isochrone < Inf)

    # remove data.table from class
    class(iso) <- c("sf", "data.frame")
    return(iso)
  }
