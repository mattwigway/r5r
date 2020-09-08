# allocate RAM memory to Java
options(java.parameters = "-Xmx16G")


# 1) build transport network, pointing to the path where OSM and GTFS data are stored
# library(r5r)
devtools::load_all(".")
library("tidyverse")
library("tictoc")

# path <- system.file("extdata", package = "r5r")
path <- "~/Repos/r5r_benchmarks/data/poa"
r5r_core <- setup_r5(data_path = path, verbose = FALSE)

# 2) load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
poi <- read.csv(system.file("extdata/poa_points_of_interest.csv", package = "r5r"))

# 3.1) calculate a travel time matrix
tic()
df <- travel_time_matrix( r5r_core,
                          origins = poi,
                          destinations = poi,
                          mode = c("WALK", "BUS"),
                          departure_datetime = lubridate::as_datetime("2019-05-20 14:00:00",
                                                                      tz = "America/Sao_Paulo"),
                          max_walk_dist = 900,  # meters
                          max_trip_duration = 120, # minutes
                          return_paths = TRUE,
                          paths_per_od = 2L,
                          verbose = FALSE
)
toc()

df %>%
  count(fromId, toId, sort = TRUE)

df %>%
  filter(fromId == "farrapos_station", toId == "praia_de_belas_shopping_center") %>%
  # mapview::mapview(xcol="board_lon", ycol="board_lat", crs=4326)
  mapview::mapview(xcol="alight_lon", ycol="alight_lat", crs=4326)

df %>%
  filter(alight_time != -1) %>%
  mutate(alight_time = alight_time / 3600) %>%
  View()
#### benchmarks
#' return_paths = FALSE : 2.662 sec elapsed
#' return_paths = TRUE  : 4.402 sec elapsed
#'
#'
#'
#'
write_csv(df, "~/ttm_with_path.csv")

