##### Reprex 1 - Parallel Computing #####
options(java.parameters = "-Xmx16G")

library(r5r)

# path <- system.file("extdata/poa", package = "r5r")
path <- "/Users/marcussaraiva/Repos/r5r_benchmarks/data/poa"
r5r_core <- setup_r5(data_path = path, verbose = FALSE)

r5r_core$silentMode()

##### input
origins <- destinations <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
trip_date = "2019-05-20"
departure_time = "14:00:00"
mode = c('WALK', 'TRANSIT')
max_street_time = 600L
max_trip_duration = 600L


##### Max threads
r5r_core$setNumberOfThreadsToMax()

system.time(
  df <- travel_time_matrix( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                            time_window = 15,
                            percentiles = c(25, 50, 75, 99),
                            mode = mode,
                            max_walk_dist = 300,
                            max_trip_duration = 60,
                            verbose = TRUE
  )
)

destination <- destinations[100,]
origin <- origins[200, ]

dit <- detailed_itineraries(r5r_core, origins = origin, destinations = destination, mode = c("WALK", "TRANSIT"),
                            # departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                            departure_datetime = as.POSIXct("20-05-2019 9:14:20",format = "%d-%m-%Y %H:%M:%S"),
                            max_walk_dist = 800,
                            max_trip_duration = 60,
                            shortest_path = FALSE
                            )


origin$lon <- origins[200, ]$lat
origin$lat <- origins[200, ]$lon

dit <- detailed_itineraries(r5r_core, origins = origin, destinations = destination, mode = c("BUS"),
                            departure_datetime = lubridate::ymd_hm("2019-05-20 24:00"),
                            max_walk_dist = Inf,
                            max_trip_duration = 30
)

df %>% drop_na() %>% nrow()
# user  system elapsed
# 12.982   0.864   1.647

##### Six threads
r5r_core$setNumberOfThreads(6L)

system.time(
  df2 <- travel_time_matrix( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            trip_date = trip_date,
                            departure_time = departure_time,
                            mode = mode,
                            max_street_time = max_street_time,
                            max_trip_duration = max_trip_duration
  )
)

# user  system elapsed
# 5.794   1.278   1.460

##### Single thread (sequential)
r5r_core$setNumberOfThreads(1L)

system.time(
  df3 <- travel_time_matrix( r5r_core = r5r_core,
                             origins = origins,
                             destinations = destinations,
                             trip_date = trip_date,
                             departure_time = departure_time,
                             mode = mode,
                             max_street_time = max_street_time,
                             max_trip_duration = max_trip_duration
  )
)

# user  system elapsed
# 4.915   0.436   4.586
