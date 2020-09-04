# allocate RAM memory to Java
options(java.parameters = "-Xmx16G")


# 1) build transport network, pointing to the path where OSM and GTFS data are stored
# library(r5r)
devtools::load_all(".")
library("tidyverse")

path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = path, verbose = FALSE)

# 2) load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
poi <- read.csv(system.file("extdata/poa_points_of_interest.csv", package = "r5r"))

# 3.1) calculate a travel time matrix
df <- travel_time_matrix( r5r_core,
                          origins = points,
                          destinations = points,
                          mode = c("WALK", "BUS"),
                          departure_datetime = lubridate::as_datetime("2019-05-20 14:00:00"),
                          max_walk_dist = 900,  # meters
                          max_trip_duration = 120, # minutes
                          return_paths = TRUE,
                          verbose = FALSE
)

# write_csv(df, "~/ttm_path_before.csv")

