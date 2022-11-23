shinyServer(function(input, output){
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
)
