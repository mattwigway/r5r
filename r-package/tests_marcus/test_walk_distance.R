library("r5r")
library("ggplot2")
library("tidyverse")

# Start R5R core
r5r_core <- setup_r5(system.file("extdata", package = "r5r"), verbose = FALSE)

# Load points of interest
points <- read.csv(system.file("extdata/poa_points_of_interest.csv", package = "r5r"))


# Configuring trip
origin <- points[10,] # Farrapos train station
destination <- points[12,] # Praia de Belas shopping mall

trip_date_time <- lubridate::as_datetime("2019-03-20 14:00:00")

max_walk_distance = Inf
max_trip_duration = 120L

paths_df <- detailed_itineraries(r5r_core = r5r_core,
                                 origins = origin, destinations = destination,
                                 departure_datetime = trip_date_time,
                                 max_walk_dist = max_walk_distance,
                                 max_trip_duration = max_trip_duration,
                                 mode = c("WALK", "BUS"),
                                 shortest_path = FALSE, verbose = FALSE)

paths_df %>%
  ggplot() +
  geom_sf(aes(colour=mode)) +
  facet_wrap(~option)

ttm <- travel_time_matrix(r5r_core, points, points, mode = c("WALK", "BUS"), trip_date_time, max_walk_dist = 2000,
                          max_trip_duration = 120L)

ttm %>%
  left_join(points, by=c("toId"="id")) %>%
  ggplot() +
  geom_point(aes(x=lon, y=lat, colour=travel_time), size=5) +
  scale_color_distiller(palette = "Spectral") +
  facet_wrap(~fromId, ncol=5) +
  theme_minimal() +
  coord_map()

