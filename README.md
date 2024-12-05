# Accessing AρρEEARS Data with R

This README explains how to use a custom R script to interact with the NASA AρρEEARS API for retrieving remote sensing data. The code authenticates users, submits tasks to process specific data products, monitors task progress, and downloads results. The functions are adapted from the [official API documentation](https://appeears.earthdatacloud.nasa.gov/api/), please refer to the original website for the latest and accurate information.

## Prerequisites

### Required Libraries:

Install and load these packages:

```r
install.packages("httr")
install.packages("jsonlite")
```

### User Credentials:

Create an account at [NASA's Earthdata portal](https://urs.earthdata.nasa.gov/home) to obtain your earthdata_username and earthdata_password. Store these securely in your script or environment variables.

## Functions

### 1. Authentication

**Function:** `auth_appeears()`

Generates a Bearer token for API access (valid for 48 hours).

**Usage:**

```r
token <- auth_appeears(earthdata_username, earthdata_password)
```

### 2. Task Specification
**Function:** `task_specify()`

Creates a JSON-formatted task for submission, specifying the product, date range, and geographical coordinates.

**Parameters:**
`task_name`: Descriptive name for the task.
`startDate`, `endDate`: Date range (MM-DD-YYYY).
`product`: Remote sensing product code.
`layer`: Data layer within the product.
`points_list`: List of latitude-longitude coordinates.

**Example:**
```r
mytask <- task_specify("snow_cover_task", "01-15-2019", "01-18-2019", "MYD10A1.061", "NDSI_Snow_Cover", points_list)
```

### 3. Task Submission
**Function:** `task_appeears()`

Submits the task to the AρρEEARS API for processing.

**Usage:**

```r
task_id <- task_appeears(token, mytask)
```

### 4. Monitor Progress
**Function:** `progress_appeears()`

Checks the status of a submitted task.

**Usage:**
```r
progress_appeears(task_id, token)
```

### 5. Download Data
**Function:** `download_appeears()`

Downloads processed data from the AρρEEARS service.

**Parameters:**

`dest_dir`: Local directory to save the file.

**Example:**

```r
download_appeears(task_id, token, "~/Downloads")
```

## Example Workflow

```r
# Authenticate
token <- auth_appeears(earthdata_username, earthdata_password)

# Load coordinates
coords <- readRDS("data/collar_data.rds")[1:2000, c("latitude", "longitude")]
points_list <- lapply(1:nrow(coords), function(i) list(
  id = as.character(i),
  latitude = coords[i, "latitude"],
  longitude = coords[i, "longitude"]
))

# Specify and submit task
mytask <- task_specify("mytask", "01-15-2019", "01-18-2019", "MYD10A1.061", "NDSI_Snow_Cover", points_list[1:100])
task_id <- task_appeears(token, mytask)

# Monitor progress
progress_appeears(task_id, token)

# Download data
download_appeears(task_id, token, "~/Downloads")
```

## Tips:

**Product List:** Explore available products at [AρρEEARS Products](https://appeears.earthdatacloud.nasa.gov/products).

**Task Limits:** Tasks can contain up to 1000 points. For larger datasets, consider submitting multiple tasks.

## References

**NASA AρρEEARS API:** [AρρEEARS Documentation](https://appeears.earthdatacloud.nasa.gov/api/)

**httr Package:** Wickham, H. (2023). httr: Tools for Working with URLs and HTTP. Retrieved from CRAN.

**jsonlite Package:** Ooms, J. (2023). jsonlite: A Robust, High Performance JSON Parser and Generator for R. Retrieved from CRAN.
