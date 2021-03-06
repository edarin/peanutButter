##---- bottom-up: user inputs panel ----##
inputsBU <- 
column(
  width=3,
  style=paste0('height: calc(98vh - 80px); padding:30px; overflow-y:scroll; border: 1px solid ',gray(0.9),'; background:',gray(0.95)),
  shinyjs::useShinyjs(),
  
  fluidRow(
    
    # select data
    selectInput(
      inputId = 'data_selectBU', 
      label = HTML('Select Country<br><small>(see <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3" target="_blank">country codes</a>)</small>'),
      choices = row.names(country_info), 
      selected = initialize_country),
    
    wellPanel(
      
      strong('Urban Settlements'),
      
      # people per housing unit
      sliderInput(
        inputId = 'people_urb',
        label = h5('Mean people per housing unit'),
        min = 1,
        max = 10,
        value = 0,
        step = 0.1),
      
      # housing units per building
      sliderInput(
        inputId = 'units_urb',            
        label = h5('Mean housing units per residential building'),
        min = 1,
        max = 10,
        value = 0,
        step = 0.1),
      
      # probability residential
      sliderInput(
        inputId = 'residential_urb',
        label = h5('Proportion residential buildings'),
        min = 0,
        max = 1,
        value = 0,
        step = 0.01)
    ),
    
    wellPanel(
      
      strong('Rural Settlements'),
      
      # people per housing unit
      sliderInput(
        inputId = 'people_rur',
        label = h5('Mean people per housing unit'),
        min = 1,
        max = 10,
        value = 0,
        step = 0.1),
      
      # housing units per building
      sliderInput(
        inputId = 'units_rur',            
        label = h5('Mean housing units per residential building'),
        min = 1,
        max = 10,
        value = 0,
        step = 0.1),
      
      # probability residential
      sliderInput(
        inputId = 'residential_rur',
        label = h5('Proportion residential buildings'),
        min = 0,
        max = 1,
        value = 0,
        step = 0.01)
    ),
    
    wellPanel(
      
      tags$style('.irs-bar, .irs-bar-edge, .irs-single, .irs-from, .irs-to, .irs-grid-pol {background-color:darkgrey; border-color:darkgrey; }'),
      
      strong('Age-sex Selection'),
      
      br(),
      'The gridded population estimates that you download will represent the population within the selected age-sex groups.',
      br(),br(),
      
      splitLayout(cellWidths=c('25%','75%'),
                  checkboxInput(inputId="female_toggleBU", label="Female", value=T),
                  shinyWidgets::sliderTextInput(inputId="female_selectBU",
                                                label=NULL,
                                                choices=c('<1','1-4','5-9','10-14','15-19','20-24','25-29','30-34','35-39','40-44','45-49','50-54','55-59','60-64','65-69','70-74','75-79','80+'),
                                                selected=c('<1', '80+'),
                                                force_edges=T,
                                                grid=T)),
      splitLayout(cellWidths=c('25%','75%'),
                  checkboxInput(inputId="male_toggleBU", label="Male", value=T),
                  shinyWidgets::sliderTextInput(inputId="male_selectBU",
                                                label=NULL,
                                                choices=c('<1','1-4','5-9','10-14','15-19','20-24','25-29','30-34','35-39','40-44','45-49','50-54','55-59','60-64','65-69','70-74','75-79','80+'),
                                                selected=c('<1', '80+'),
                                                force_edges=T,
                                                grid=T)),
      'Note: The on-screen results represent total populations and do not change with your age-sex selection.'
      )
  )
)

##---- top-down: user input panel ----##
inputsTD <- 
  column(
    width=3,
    style=paste0('height: calc(98vh - 80px); padding:30px; overflow-y:scroll; border: 1px solid ',gray(0.9),'; background:',gray(0.95)),
    shinyjs::useShinyjs(),
    
    fluidRow(
      
      # select data
      selectInput(
        inputId = 'data_selectTD', 
        label = HTML('Select Country<br><small>(see <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3" target="_blank">country codes</a>)</small>'),
        choices = row.names(country_info), 
        selected = initialize_country),
      
      # upload geojson
      strong('Upload Polygons (GeoJson)'),
      
      fileInput("user_json", 
                NULL,
                multiple = FALSE,
                accept = c("application/json",".geojson",".json"),
                buttonLabel = 'Browse'),
      
      selectInput(inputId = 'popcol', 
                  label = 'Column name with population totals',
                  choices = '(no polygons uploaded)'),
      
      # age-sex sliders
      strong('Age-sex Selection'),
      
      br(),
      'The gridded population estimates that you download will represent the population within the selected age-sex groups.',
      br(),br(),
      
      splitLayout(cellWidths=c('25%','75%'),
                  
                  checkboxInput(inputId="female_toggleTD", label="Female", value=T),
                  
                  shinyWidgets::sliderTextInput(inputId="female_selectTD",
                                                label=NULL,
                                                choices=c('<1','1-4','5-9','10-14','15-19','20-24','25-29','30-34','35-39','40-44','45-49','50-54','55-59','60-64','65-69','70-74','75-79','80+'),
                                                selected=c('<1', '80+'),
                                                force_edges=T,
                                                grid=T)),
      
      splitLayout(cellWidths=c('25%','75%'),
                  
                  checkboxInput(inputId="male_toggleTD", label="Male", value=T),
                  
                  shinyWidgets::sliderTextInput(inputId="male_selectTD",
                                                label=NULL,
                                                choices=c('<1','1-4','5-9','10-14','15-19','20-24','25-29','30-34','35-39','40-44','45-49','50-54','55-59','60-64','65-69','70-74','75-79','80+'),
                                                selected=c('<1', '80+'),
                                                force_edges=T,
                                                grid=T))
    )
  )

##---- MAIN PANEL ----##
ui <- tagList(

tags$style(HTML(".navbar-nav {float:none !important;}
                .navbar-nav > li:nth-child(4){float:right}")),

navbarPage(
  title='peanutButter (beta)',              
  footer=tags$footer(HTML(paste0('<a href="https://github.com/wpgp/peanutButter" target="_blank">peanutButter v',packageVersion('peanutButter'),'</a>')),
                     align = 'right'),
  inverse=F,
  
  ##-- tab: bottom-up --##
  tabPanel(
    title = 'Bottom-up',                      
    
    fluidRow(
      
      # inputs panel (left)
      inputsBU,
      
      # results panel (center)
      column(
        width = 9,
        style='height: calc(98vh - 80px)',
        h4('Bottom-up Population Estimates'),
        div(style='width:500px',
          HTML('The bottom-up tool will apply your estimates of mean people per building evenly across individual buildings and then aggregate buildings to estimate population size for each ~100 m grid cell.<br><br>
                Move the sliders (panel to the left) to update the population estimates (table below) until you are satisfied that the settings and the results are reasonable.<br><br>
                Use the "Gridded Population Estimates" button to download a 100 meter population grid (geotiff raster, WGS84) created by applying your settings to a high resolution map of building footprints.<br><br>')
          ),
        strong("Results"),
        tableOutput('table_results'),
        downloadButton('raster_buttonBU', 'Gridded Population Estimates', style='width:405px'),br(),br(),
        downloadButton('table_buttonBU', 'Settings', style='width:200px'),
        downloadButton('source_buttonBU', 'Source Files', style='width:200px')
        )
      )
    ),
  
  ##-- tab: top-down --##
  tabPanel(
    title = 'Top-down',

    fluidRow(

      # inputs panel (left)
      inputsTD,

      # results panel (center)
      column(
        width = 9,
        style='height: calc(98vh - 80px)',

        h4('Top-down Population Estimates'),
        div(style='width:500px',
            HTML('The top-down tool allows you to disaggregate known population totals from administrative units (or other polygons) into gridded population estimates based on a high resolution map of building footprints.<br><br> 
                 Provide a polygon shapefile (GeoJson format) that contains the total population for each polygon in the first column.<br><br>
                 After you upload your polygons, click the "Gridded population estimates" button and the peanutButter application will disaggregate your population totals into a 100 m grid based on building footprints.<br><br>')
            ),

        downloadButton('raster_buttonTD', 'Gridded Population Estimates', style='width:405px'),
        downloadButton('source_buttonTD', 'Source Files', style='width:200px'),
        br(),br()
        )
      )
    ),
  
  ##---- tab: About ----##
  tabPanel(
    title = 'About',
    tags$iframe(style='overflow-y:scroll; width:100%; height: calc(98vh - 80px)',
                frameBorder='0',
                src='about.html')
    ),
  
  ##---- tab: WorldPop ----##
  tabPanel(
    a(href='https://www.worldpop.org', target='_blank', 
      style='padding:0px',
      img(src='logoWorldPop.png', 
          style='height:30px; margin-top:-30px; margin-left:10px'))
    )
  )
)
