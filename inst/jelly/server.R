shinyServer(
function(input, output, session){

  options(shiny.maxRequestSize=30*1024^2)
  
  # reactive values
  rv <- reactiveValues()

  # cleanup temporary tifs
  observeEvent(rv$temp_tifs, {
    unlink(rv$temp_tifs)
    unlink(file.path(tempdir(), 'raster'), recursive=T)
    
    shinyjs::enable('raster_buttonBU')
    shinyjs::enable('table_buttonBU')
    shinyjs::enable('source_buttonBU')
    shinyjs::enable('raster_buttonTD')
    shinyjs::enable('source_buttonTD')
  })
  
  # Syncronize country selection between bottom-up and top-down tabs
  observeEvent(input$data_selectBU, {
    rv$data_select <- input$data_selectBU
    updateSelectInput(session, 'data_selectTD', selected=input$data_selectBU)
  })
  
  observeEvent(input$data_selectTD, {
    rv$data_select <- input$data_selectTD
    updateSelectInput(session, 'data_selectBU', selected=input$data_selectTD)
  })
  
  ##---- load data ----##
  observeEvent(rv$data_select, {

    # country info
    rv$country_info <- country_info[rv$data_select,]

    # paths to source files
    rv$path_readme1 <- 'XXX_buildings_v1_0_README.pdf'
    if(file.exists(file.path(srcdir,rv$path_readme1))){
      rv$path_readme1 <- file.path(srcdir,rv$path_readme1)
    } else {
      rv$path_readme1 <- NULL
    }

    rv$path_readme2 <- 'XXX_agesex_README.pdf'
    if(file.exists(file.path(srcdir,rv$path_readme2))){
      rv$path_readme2 <- file.path(srcdir,rv$path_readme2)
    } else {
      rv$path_readme2 <- NULL
    }
    
    rv$path_buildings <- paste0(rv$country_info$country, '_buildings_v1_0_count.tif')
    if(file.exists(file.path(srcdir,rv$path_buildings))){
      rv$path_buildings <- file.path(srcdir,rv$path_buildings)
    } else {
      stop(paste('Source file not in source directory:',rv$path_buildings))
    }
    
    rv$path_urban <- paste0(rv$country_info$country, '_buildings_v1_0_urban.tif')
    if(file.exists(file.path(srcdir,rv$path_urban))){
      rv$path_urban <- file.path(srcdir,rv$path_urban)
    } else {
      stop(paste('Source file not in source directory:',rv$path_urban))
    }
    
    rv$path_agesex_regions <- paste0(rv$country_info$country, '_agesex_regions.tif')
    if(file.exists(file.path(srcdir,rv$path_agesex_regions))){
      rv$path_agesex_regions <- file.path(srcdir,rv$path_agesex_regions)
    } else {
      stop(paste('Source file not in source directory:',rv$path_agesex_regions))
    }
    
    rv$path_agesex_table <- paste0(rv$country_info$country, '_agesex_table.csv')
    if(file.exists(file.path(srcdir,rv$path_agesex_table))){
      rv$path_agesex_table <- file.path(srcdir,rv$path_agesex_table)
    } else {
      stop(paste('Source file not in source directory:',rv$path_agesex_table))
    }

    # slider values
    updateSliderInput(session, 'people_urb', value=rv$country_info$people_urb)
    updateSliderInput(session, 'units_urb', value=rv$country_info$units_urb)
    updateSliderInput(session, 'residential_urb', value=rv$country_info$residential_urb)
    updateSliderInput(session, 'people_rur', value=rv$country_info$people_rur)
    updateSliderInput(session, 'units_rur', value=rv$country_info$units_rur)
    updateSliderInput(session, 'residential_rur', value=rv$country_info$residential_rur)

    # popup message
    rv$popup_message <- c()
    
    if(rv$country_info$wopr & rv$country_info$woprVision){
      rv$popup_message[1] <- paste0('There are customized gridded population estimates available for ',rv$data_select,'. These data are available for download from the <a href="https://wopr.worldpop.org/?',rv$data_select,'" target="_blank">WorldPop Open Population Repository (WOPR)</a> and you can explore those results on an interactive map using the <a href="https://apps.worldpop.org/woprVision" target="_blank">woprVision web application</a>.')
    } else if(rv$country_info$wopr) {
      rv$popup_message[1] <- paste0('There are customized gridded population estimates available for ',rv$data_select,'. These data are available for download from the <a href="https://wopr.worldpop.org/?',rv$data_select,'" target="_blank">WorldPop Open Population Repository (WOPR)</a>.')
    }

    if(rv$country_info$partial_footprints){
      rv$popup_message[length(rv$popup_message)+1] <- paste0('Warning: The building footprints for ',rv$data_select,' do not have complete national coverage. Download the source files to see the coverage.')
    }

    if(!is.null(rv$popup_message[1])){
      showModal(modalDialog(HTML(paste(rv$popup_message,collapse='<br><br>')),
                            title='Friendly Message:',
                            footer=tagList(modalButton('Okay, thanks.'))
      ))
    }
  })

  ##---- bottom-up ----##
  
  # quick-calculate national population results (bottom-up)
  observe({
    rv$pop_urb <- rv$country_info$urb_count * input$residential_urb * input$units_urb * input$people_urb
    rv$pop_rur <- rv$country_info$rur_count * input$residential_rur * input$units_rur * input$people_rur

    rv$pop_total <- rv$pop_urb + rv$pop_rur

    rv$table <- data.frame(settings=matrix(c(prettyNum(round(rv$pop_total), big.mark=','),
                                             prettyNum(round(rv$pop_urb), big.mark=','),
                                             prettyNum(round(rv$pop_rur), big.mark=','),
                                             prettyNum(round(rv$country_info$urb_count), big.mark=','),
                                             prettyNum(round(rv$country_info$rur_count), big.mark=','),
                                             prettyNum(round(input$people_urb,1), big.mark=','),
                                             prettyNum(round(input$units_urb,1), big.mark=','),
                                             paste0(round(input$residential_urb*100),'%'),
                                             prettyNum(round(input$people_rur,1), big.mark=','),
                                             prettyNum(round(input$units_rur,1), big.mark=','),
                                             paste0(round(input$residential_rur*100),'%')
                                             ),
                                           ncol=1),
                           row.names=c('Population Total',
                                       'Population Urban',
                                       'Population Rural',
                                       'Buildings Urban',
                                       'Buildings Rural',
                                       'Urban: People per housing unit',
                                       'Urban: Housing units per building',
                                       'Urban: Proportion residential buildings',
                                       'Rural: People per housing unit',
                                       'Rural: Housing units per building',
                                       'Rural: Proportion residential buildings'
                                       ))
  })

  # results table (bottom-up)
  output$table_results <- renderTable(data.frame(rv$table[c('Population Total',
                                                            'Population Urban',
                                                            'Population Rural',
                                                            'Buildings Urban',
                                                            'Buildings Rural'),], 
                                                 row.names=c('Population Total',
                                                             'Population Urban',
                                                             'Population Rural',
                                                             'Buildings Urban',
                                                             'Buildings Rural')),
                                      digits = 0,
                                      striped = T,
                                      colnames = F,
                                      rownames = T,
                                      width = 405,
                                      format.args = list(big.mark=",", decimal.mark="."))

  # observe age-sex selection (bottom-up)
  observe({
    
    # format age-sex selection to column names
    rv$agesex_selectBU <- agesexLookup(male = input$male_toggleBU,
                                       female = input$female_toggleBU,
                                       male_select = input$male_selectBU,
                                       female_select = input$female_selectBU)
    
    # syncronize settings in top-down tab
    updateCheckboxInput(session, 'male_toggleTD', value=input$male_toggleBU)
    updateCheckboxInput(session, 'female_toggleTD', value=input$female_toggleBU)
    shinyWidgets::updateSliderTextInput(session, 'male_selectTD', selected=input$male_selectBU)
    shinyWidgets::updateSliderTextInput(session, 'female_selectTD', selected=input$female_selectBU)
  })
  
  ## buttons ##
  
  # download settings button (bottom-up)
  output$table_buttonBU <- downloadHandler(
    filename = function() {
      paste0(rv$data_select,'_settings_',format(Sys.time(), "%Y%m%d%H%M"),'.csv')
    },
    content = function(file) {
      withProgress({
        write.csv(rv$table, file, row.names=T)
      },
      message='Preparing data:',
      detail='Creating .csv spreadsheet with your settings...',
      value=1)
  })
  
  # download raster button (bottom-up)
  output$raster_buttonBU <- downloadHandler(
    filename = function() {
      paste0(rv$data_select,'_population_',format(Sys.time(), "%Y%m%d%H%M"),'.tif')
    },
    content = function(file) {
      withProgress({
        tryCatch(
          withCallingHandlers({
            
            shinyjs::disable('raster_buttonBU')
            shinyjs::disable('table_buttonBU')
            shinyjs::disable('source_buttonBU')
            shinyjs::disable('raster_buttonTD')
            shinyjs::disable('source_buttonTD')
            
            # bottom-up aggregation
            x <- aggregator(buildings = raster::raster(rv$path_buildings),
                            urban = raster::raster(rv$path_urban),
                            people_urb = input$people_urb,
                            units_urb = input$units_urb,
                            residential_urb = input$residential_urb,
                            people_rur = input$people_rur,
                            units_rur = input$units_rur,
                            residential_rur = input$residential_rur)
            
            # age-sex adjustment
            if(length(rv$agesex_selectBU) < 36){
              
              setProgress(value=1, message='Preparing data:', detail='Updating your gridded population estimates to represent the selected age-sex groups...')
              
              x <- demographic(population = x,
                               group_select = rv$agesex_selectBU,
                               regions = raster::raster(rv$path_agesex_regions),
                               proportions = read.csv(rv$path_agesex_table))
            }
            
            # save result
            raster::writeRaster(x = x,
                                filename = file)
            
            rv$temp_tifs <- list.files(tempdir(), full.names=T)[grepl('.tif',list.files(tempdir()))]

          }, warning=function(w){
            showNotification(as.character(w), type='warning', duration=20)
          }), 
          error=function(e){
            showNotification(as.character(e), type='error', duration=20)
          }, finally={
            rm(x);gc()
          })
      },
      message='Preparing data:',
      detail='Creating .tif raster with your gridded population estimates...',
      value=1)
    })
  
  # download source button (bottom-up)
  output$source_buttonBU <- downloadHandler(
    filename = function() paste0(rv$data_select,'_source_',format(Sys.time(), "%Y%m%d%H%M"),'.zip'),
    content = function(file) {
      withProgress({
        zip::zipr(zipfile = file,
                  files = c(rv$path_buildings,
                            rv$path_urban,
                            rv$path_agesex_regions,
                            rv$path_agesex_table,
                            rv$path_readme1,
                            rv$path_readme2)
        )
      },
      message='Preparing data:',
      detail='Creating .zip archive with source data...',
      value=1)
    })
  
  ##---- top-down ----##
  
  # observe file upload (top-down)
  observeEvent(input$user_json, {
    if(is.null(input$user_json[,'datapath'])){
      updateSelectInput(session, 'popcol', choices='(no polygons uploaded)')
      shinyjs::disable('raster_buttonTD')
    } else {
      updateSelectInput(session, 'popcol', choices=names(sf::st_read(input$user_json[,'datapath'], quiet=T)))
      shinyjs::enable('raster_buttonTD')
    }
  })  
  
  # observe age-sex selection (top-down)
  observe({
    rv$agesex_selectTD <- agesexLookup(male = input$male_toggleTD,
                                       female = input$female_toggleTD,
                                       male_select = input$male_selectTD,
                                       female_select = input$female_selectTD)
    
    updateCheckboxInput(session, 'male_toggleBU', value=input$male_toggleTD)
    updateCheckboxInput(session, 'female_toggleBU', value=input$female_toggleTD)
    shinyWidgets::updateSliderTextInput(session, 'male_selectBU', selected=input$male_selectTD)
    shinyWidgets::updateSliderTextInput(session, 'female_selectBU', selected=input$female_selectTD)
  })
  
  ## buttons ##

  # download raster button (top-down)
  output$raster_buttonTD <- downloadHandler(
    filename = function() {
      paste0(rv$data_select,'_population_',format(Sys.time(), "%Y%m%d%H%M"),'.tif')
    },
    content = function(file) {
      withProgress({
        tryCatch(
          withCallingHandlers({
            
            if(is.null(input$user_json[,'datapath'])) {
              stop('You must upload a geojson file that contains polygons with the total population of each in a column of the attribute table.', call.=F)
            }
            
            shinyjs::disable('raster_buttonBU')
            shinyjs::disable('table_buttonBU')
            shinyjs::disable('source_buttonBU')
            shinyjs::disable('raster_buttonTD')
            shinyjs::disable('source_buttonTD')
            
            # top-down disaggregation
            x = disaggregator(feature = sf::st_read(input$user_json[,'datapath'], quiet=T), 
                              buildings = raster::raster(rv$path_buildings),
                              popcol = input$popcol)
            
            # age-sex adjustment
            if(length(rv$agesex_selectBU) < 36){
              
              setProgress(value=1, message='Preparing data:', detail='Updating your gridded population estimates to represent the selected age-sex groups...')
              
              x <- demographic(population = x,
                               group_select = rv$agesex_selectBU,
                               regions = raster::raster(rv$path_agesex_regions),
                               proportions = read.csv(rv$path_agesex_table))
              }
            
            # save result
            raster::writeRaster(x, filename = file)
            
            rv$temp_tifs <- list.files(tempdir(), full.names=T)[grepl('.tif',list.files(tempdir()))]
            
            }, warning=function(w){
              showNotification(as.character(w), type='warning', duration=20)
          }), 
          error=function(e){
            showNotification(as.character(e), type='error', duration=20)
          }, finally={
            shinyjs::reset('user_json')
            rm(x);gc()
          })  
        },
        message='Preparing data:',
        detail='Creating .tif raster with your gridded population estimates...',
        value=1)  
      })
  
  # download source button (top-down)
  output$source_buttonTD <- downloadHandler(
    filename = function() {
      paste0(rv$data_select,'_source_',format(Sys.time(), "%Y%m%d%H%M"),'.zip')
    },
    content = function(file) {
      withProgress({
        zip::zipr(zipfile = file,
                  files = c(rv$path_buildings,
                            rv$path_agesex_regions,
                            rv$path_agesex_table,
                            rv$path_readme1,
                            rv$path_readme2)
        )
      },
      message='Preparing data:',
      detail='Creating .zip archive with source data...',
      value=1)
    })
})

