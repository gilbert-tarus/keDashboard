library(shiny)
library(plotly)
library(leaflet)
ui <- fluidPage(
 
 titlePanel("Kenyan Climate"),
 sidebarLayout(
  sidebarPanel(
   uiOutput("rname"),
   uiOutput("year"),
   radioButtons("period", "Choose a period:", 
                c("All the time" = "all", "From to Years" = "yearbegin"),
                selected = "all"),
   uiOutput("slider")
   
  ),
  mainPanel(
   tabsetPanel(
    type = "tabs",
    tabPanel( "Plots",
   plotlyOutput("plot1"),
   plotlyOutput("barplot1")
   ),
   tabPanel("Summaries", verbatimTextOutput('Summ'),
            plotlyOutput("boxplot1"),
            plotlyOutput("boxplot2")),
   tabPanel("Map",
            leafletOutput("keMap", width = "1200px", height = "800px")
            )
  )
  )
  ),

hr(),
 fluidRow(
  column(4, h3("Kenya Climate Data"), h5("by Gilbert Tarus"), p("Peer-graded Assignment: Course Project: Shiny Application and Reproducible Pitch")),
  column(6, 
         h2("Overview"),
         p("The dashboard displays the climate change of Kenya from 1991 to 2016. The climatic factors in this context 
           are Temperature (in degree celsius) and Rainfall (mm). The application also displays the Summaries of 
           the temperature and rainfall and also the map of Kenya showing the population and the County when you hover the circles."),
         h2("How to Use"),
         
         p("It is a simple application where you can choose the variable to view the plot 
           for from the drop down menu on the sidebar panel. You can also see the averages 
           for the respective variables spanning all years in form of bar plot below the line plot. 
           They are measurements of either temperature in degree celsius or rainfall in mm."),
         
         HTML( "<ul>
                  <li> The application has two panels, the <b>sidebar panel</b> and the <b>main panel</b>.</li>  
                    <ul>
                      <li><b>sidebar panel</b>: Here, you can choose a variable to view from the drop-down list. 
                      The changes are visible on the main panel on select. Also, you can choose a period you want
                      to display the results: <b>*All the time</b>* (*default*) shows the results for all years and 
                      <b>From to Years</b> on select displays the slider which you can drag horizontally to choose 
                      range of years you want to see the results. The respective changes take place on the <b>Plot</b> tab.</li>
                      <li> <b>main panel</b>: Here, there are three tabs: <b>Plots, Summaries</b> and <b>Map</b>.
                          <ul>
                            <li> <b>Plots</b>: This is the primary tab. It shows *line plot* and a *barplot*. They show
                            the results of the selections from the sidebar panel. By default, the plots show line plot 
                            and bar plot of monthly averages of temperature in degrees celsius for the all years. 
                            You can change this from the `sidebar panel` options.<li>
                            <li> <b>Summaries</b>: This tab shows the summary statistics for all the temperature and rainfall 
                            measurements from 1991 to 2016 including *mean, standard deviation, median, range* among others. 
                            Below these summaries are two plots showing the `boxplots` of the measurements for all years grouped by Months. 
                            Here you can see the difference in the rainfall and temperature measurements across all months for all years.
                            For example, across all years, which month has got the highest rainfall or temperature measurement? 
                            You can hover the plots to see the values of `median and quartiles`. </li>
                            <li> <b>Map</b>: Displays the map of Kenya. The Circles, on hover, displays the name of the county and 
                            its approximate population. This tab is not associated with the selections on the sidebar panel. 
                            You can Zoom in, Zoom Out or drag the map.</li>
                          </ul>
                    </ul>
                 </ul>"
                 ),
         br(),
         br(),
         HTML(
          '<footer>
          Powered by Arrow of Code © 2022
          </footer>'
         )
         
)

)
)


server <- function(input, output){
 library(tidyverse)
 library(janitor)
 library(psych)
 #Data 
 df1 <- read_csv("data/kenya-climate-data-1991-2016-temp-degress-celcius.csv")
 df2 <- read_csv("data/kenya-climate-data-1991-2016-rainfallmm.csv")
 ke_data <- read_csv("data/ke.csv")
 data_climate <- merge(df1,df2) %>% clean_names() %>% 
  separate(month_average, into = c("month", "other")) %>% 
  select(-other) %>%
  mutate(Month = factor(month, levels = month.abb))
 
 
 output$rname <- renderUI({selectInput("rname", "Choose a variable:", as.list(names(data_climate))[3:4])}) 

 output$slider <- renderUI({
  if (input$period == "yearbegin"){ sliderInput("slider", label = "Years range", 
                                                min = 1991, max = 2016, value = c(2001,2006), sep = "")} })
 output$plot1 <- renderPlotly({
  if (input$period == "all") { 
   dt <- data_climate 
   }
  
  if (input$period == "yearbegin") { dt <- data_climate %>% filter(year%in%input$slider[1]:input$slider[2])}
  
  plot_ly(dt, x = ~as.factor(year), 
          y = ~dt[,input$rname], color = ~month,
          type = "scatter", mode = "lines") %>% 
   layout(title = paste("Kenya Climate (", input$rname, " )", sep = ""), xaxis = list(title = "Period in Years"), yaxis = list(title = input$rname))
  })
 output$barplot1 <- renderPlotly({
  
  p <- data_climate %>% 
   select(year, month, col_main = input$rname) %>% 
   group_by(month) %>% 
   summarise(Mean = mean(col_main)) %>% 
   mutate(month = reorder(month, Mean)) %>% 
   ggplot(aes(x = month, y = Mean, fill = month))+
   geom_bar(stat = "identity")+
   labs(y = paste("Mean ", str_split(str_to_title(input$rname), pattern = "_")[[1]][1]," (",
                  str_split(str_to_title(input$rname), pattern = "_")[[1]][2],")", sep = ""))+
   coord_flip()
  ggplotly(p)
 })
 output$Summ <- renderPrint({
  data_climate %>% 
   select("Temperature (Celsius)" = temperature_celsius, `Rainfall (mm)` = rainfall_mm) %>% 
   describe()
 })
 output$keMap <- renderLeaflet({
 my_map <- ke_data %>% leaflet() %>% addTiles() %>% 
  addCircleMarkers(lat = ~lat, lng = ~lng, weight = 1, radius = sqrt(ke_data$population) * 0.03125, 
                   popup = paste(ke_data$city,"<br>Pop: ",ke_data$population))
 my_map
 })
 output$boxplot1 <- renderPlotly({
  data_climate %>% 
   plot_ly(y = ~temperature_celsius, color = ~month, type = "box") %>% 
   layout(showlegend = FALSE, xaxis = list(title = "Temperature (<sup>o</sup>C)"))
 })
 
 output$boxplot2 <- renderPlotly({
  data_climate %>% 
   plot_ly(y = ~rainfall_mm, color = ~month, type = "box") %>% 
   layout(showlegend = FALSE, xaxis = list(title = "Rainfall (mm)"))
  
 })
}


shinyApp(ui, server)
