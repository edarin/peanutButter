# cleanup
rm(list=ls()); gc(); cat("\014"); try(dev.off(), silent=T)

# working directory
setwd(file.path(dirname(rstudioapi::getSourceEditorContext()$path),'..'))

# source directory
srcdir <- '//worldpop.files.soton.ac.uk/worldpop/Projects/WP517763_GRID3/Working/git/peanutButter'

# country list
files <- list.files(srcdir)
country_list <- c()
for(i in 1:length(files)){
  country_list[i] <- unlist(strsplit(x = files[i], 
                                     split = '_'))[1]
}  
# country_list <- sort(unique(c(country_list,as.character(peanutButter:::country_info$country))))
country_list <- sort(unique(country_list))

# check files exist
for(country in country_list){
  count.exists <- paste0(country,'_buildings_v1_0_count.tif') %in% files
  type.exists <- paste0(country,'_buildings_v1_0_urban.tif') %in% files
  
  # drop country if missing files
  if(!count.exists | !type.exists){
    country_list <- country_list[-which(country_list==country)]
  }
}

# setup country info data frame
country_info <- data.frame(country=as.character(country_list))
row.names(country_info) <- country_list

country_info[row.names(peanutButter:::country_info),names(peanutButter:::country_info)[-1]] <- peanutButter:::country_info[,-1]

# calculate country info

# building counts
for(country in country_list){
  if(is.na(country_info[country,'bld_count']) | is.na(country_info[country,'urb_count']) | is.na(country_info[country,'rur_count'])){
    print(country)
    
    # load rasters
    buildings <- raster::raster(file.path(srcdir,paste0(country,'_buildings_v1_0_count.tif')))
    urban <- raster::raster(file.path(srcdir,paste0(country,'_buildings_v1_0_urban.tif')))
    
    # building counts
    country_info[country,'bld_count'] <- raster::cellStats(buildings, 'sum')
    country_info[country,'urb_count'] <- sum(buildings[urban==1], na.rm=T)
    country_info[country,'rur_count'] <- country_info[country,'bld_count'] - country_info[country,'urb_count']
  }
}

# default settings
defaults <- read.csv('data-raw/defaults.csv',stringsAsFactors=F)
row.names(defaults) <- defaults$country

for(country in country_list){
  i <- ifelse(country %in% defaults$country, country, 'DEF')
  for(parm in c('people_urb','units_urb','residential_urb','people_rur','units_rur','residential_rur')){
    country_info[country,parm] <- defaults[i,parm]      
  }
  country_info[country,c('residential_urb','residential_rur')] <- min(1,defaults[country,'population'] / (country_info[country,'urb_count']*country_info[country,'units_urb']*country_info[country,'people_urb'] + country_info[country,'rur_count']*country_info[country,'units_rur']*country_info[country,'people_rur']))
}

# wopr
country_info$wopr <- country_info$country %in% unique(wopr::getCatalogue()$country)
country_info$woprVision <- country_info$country %in% unique(wopr::getCatalogue(spatial_query=T)$country)

country_info$partial_footprints <- country_info$country %in% c('COD')

# save as internal R package file
usethis::use_data(country_info, internal=T, overwrite=F)
