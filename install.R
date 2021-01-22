install.packages('r5r')

# prebuild graph so that binder runs are quick
# points to directory with data
data_path <- system.file("extdata/poa", package = "r5r")

r5r_core <- setup_r5(data_path, verbose = FALSE)