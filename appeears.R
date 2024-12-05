# load library
library(httr)
library(jsonlite)

# set params ----
earthdata_username <- "USERNAME"
earthdata_password <- "PASSWORD"

# FUNCTION: authenticate, run every 48 hours ----
auth_appeears <- function(earthdata_username, earthdata_password) {
  secret <- base64_enc(paste(earthdata_username, earthdata_password, sep = ":"))
  response <- POST("https://appeears.earthdatacloud.nasa.gov/api/login",add_headers("Authorization" = paste("Basic", gsub("\n", "", secret)),"Content-Type" = "application/x-www-form-urlencoded;charset=UTF-8"), body = "grant_type=client_credentials")
  token_response <- prettify(toJSON(content(response), auto_unbox = TRUE))
  token <- paste("Bearer", fromJSON(token_response)$token)
  return(token)
}
# FUNCTION: specify task ----
task_specify <- function(task_name, startDate, endDate, product, layer, points_list) {
  
  # Date format: MM-DD-YYYY

  task <- list(
    task_type = "point",
    task_name = task_name,
    params = list(
      dates = list(
        list(
          startDate = startDate,
          endDate = endDate
        )
      ),
      layers = list(
        list(
          product = product,
          layer = layer
        )
      ),
      coordinates = points_list
    )
  )
  task <- toJSON(task, auto_unbox = TRUE)
  return(task)
}
# FUNCTION: submit task ----
task_appeears <- function(token, task) {
  response <- POST("https://appeears.earthdatacloud.nasa.gov/api/task", body = task, encode = "json", add_headers(Authorization = token, "Content-Type" = "application/json"))
  task_id <- content(response)$task_id
  if(is.null(task_id)) {
    print(paste0("Task submission failed, error message: ",content(response)$message)) 
    return()
  }
  else{
    print(paste("Task submitted. Task ID:", task_id))
    return(task_id)
  }
}

# FUNCTION: check progress ----
progress_appeears <- function(task_id, token) {
  response <- GET(paste("https://appeears.earthdatacloud.nasa.gov/api/task/", task_id, sep = ""), add_headers(Authorization = token))
  
  status <- content(response)$status
  print(paste("Task status:", status))
}

# FUNCTION: download data ----
download_appeears <- function(task_id, token, dest_dir) {
  # Retrieve download links
  bundle_response <- GET(paste("https://appeears.earthdatacloud.nasa.gov/api/bundle/", task_id, sep = ""), add_headers(Authorization = token))
  bundle_response <- prettify(toJSON(content(bundle_response), auto_unbox = TRUE))
  bundle_response
  
  # get file id of the file of csv format
  file_id <- unlist(fromJSON(bundle_response)$files[which(fromJSON(bundle_response)$files$file_type == "csv"),]$file_id)
  file_name <- unlist(fromJSON(bundle_response)$files[which(fromJSON(bundle_response)$files$file_type == "csv"),]$file_name)

  filepath <- paste(dest_dir, file_name, sep = '/')
  suppressWarnings(dir.create(dirname(filepath)))
  
  # write the file to disk using the destination directory and file name 
  response <- GET(paste("https://appeears.earthdatacloud.nasa.gov/api/bundle/", task_id, '/', file_id, sep = ""),
                  write_disk(filepath, overwrite = TRUE), progress(), add_headers(Authorization = token))
}


# ================================================
# ----Example----
# ================================================

# authenticate (need to get new token every 48 hours)
token <- auth_appeears(earthdata_username, earthdata_password)

# load movement data
coords <- readRDS("data/collar_data.rds")[1:2000,c("latitude","longitude")]# The projection of any coordinates must be in a geographic projection
points_list <- lapply(1:nrow(coords), function(i) list(
  id = as.character(i),
  latitude = coords[i, "latitude"],  # Correct order
  longitude = coords[i, "longitude"]
))

# specify tasks
mytask <- task_specify(task_name = "mytask", startDate = "01-15-2019", endDate = "01-18-2019", product = "MYD10A1.061", layer = "NDSI_Snow_Cover", points_list = points_list[1:100]) 
# Tips 1. product list https://appeears.earthdatacloud.nasa.gov/products
# Tips 2. product name = product.version
# Tips 3. No. points cannot exceed 1000 in one task. Tasks will be processed one by one, and is a bit slow (could take ~ 5- 10 mins for daily RS products). But I assume if you have more than one token (more than one account) then you can have multiple tasked being processed at the same time.
# Tips 4. The startDate and endDate should be in the format of MM-DD-YYYY

# submit tasks
mytask_id <- task_appeears(token, mytask)

# check progress
progress_appeears(mytask_id, token)
# Tips: If the task is still in progress (queued, processing), you can run this line of code every 2-3 minutes to check the progress (it will print out the status of the task)

# download data
download_appeears(mytask_id, token, "~/Downloads")
# replace the dir with your own existing directory, file name would be your task name + product name.csv



