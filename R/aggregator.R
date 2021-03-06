#' Aggregate population estimates from buildings
#' @description Create population raster using the peanut butter method with building footprints.
#' @param buildings raster. A "raster" object with building counts per pixel
#' @param urban raster. A "raster" object with binary map of urban areas (i.e. 0 and 1) 
#' @param people_urb numeric. Average number of people per housing unit in urban areas
#' @param units_urb numeric. Average number of housing units per building in urban areas
#' @param residential_urb numeric. Probability of residential building in urban areas
#' @param people_rur numeric. Average number of people per housing unit in rural areas
#' @param units_rur numeric. Average number of housing units per building in rural areas
#' @param residential_rur numeric. Probability of residential building in rural areas
#' @export

aggregator <- function(buildings, urban, 
                      people_urb=5, units_urb=1, residential_urb=0.5, 
                      people_rur=5, residential_rur=0.5, units_rur=1){
  
  # pop raster
  pop_raster <- raster::raster(buildings)
  
  # vectorize rasters
  buildings <- buildings[]
  urban <- as.logical(urban[])
  rural <- !urban
  
  urban[is.na(urban)] <- F
  rural[is.na(rural)] <- F
  
  # rasterize urban population
  pop_raster[urban] <- buildings[urban] * residential_urb * units_urb * people_urb
  
  # rasterize rural population
  pop_raster[rural] <- buildings[rural] * residential_rur * units_rur * people_rur
  
  return(pop_raster)
}