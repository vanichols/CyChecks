library(shiny)
require(ggplot2)
require(dplyr)
require(tidyr)
require(stringr)
library(DT)

# read in data
load(file = "sals_dept.rda")
load(file = "sals_dept_profs.rda")
sals_dept <- sals_dept %>% filter(!is.na(gender))
department <- c("All departments", sort(unique(as.character(sals_dept$department))))
fiscal_year <- c("All years", sort(unique(as.character(sals_dept$fiscal_year))))


ui <- fluidPage(
  # App Title
  titlePanel("CyChecks"),

  # Sidebar # - Based on gender
  sidebarPanel(
    selectInput("department", label = ("Department"), # - Based on gender
                choices = department,
                selected = "AGRONOMY"),
    selectInput("fiscal_year", label = ("Year"), # - Based on gender
                choices = fiscal_year,
                selected = "2018")
  ),
  mainPanel(
    tabsetPanel(
      tabPanel("All", plotOutput(outputId = "allDat"), DT::dataTableOutput("allDatTab")),
      tabPanel("Professors", plotOutput(outputId = "prof"), DT::dataTableOutput("profTab")),
      tabPanel("Post Docs", plotOutput(outputId = "postdoc"), DT::dataTableOutput("postdocTab"))
    )
  )
)

# server
server <- function(input, output){
  liq_all <- reactive({
    # Show all departments and all years
    if (input$department == "All departments" & input$fiscal_year == 'All years'){
      sals_dept %>%
        filter(!is.na(total_salary_paid)) %>%
        select("total_salary_paid", "gender", "position")
    }
    # Show all departments but filter on years
    else if (input$department == "All departments"){
      sals_dept %>%
        filter(!is.na(total_salary_paid),fiscal_year == input$fiscal_year) %>%
        select("total_salary_paid", "gender", "position")
    }
    # Show all years but filter on department
    else if (input$fiscal_year == "All years"){
      sals_dept %>%
        filter(!is.na(total_salary_paid),department == input$department) %>%
        select("total_salary_paid", "gender", "position")
    }
    # Filter on department and year
    else {
      sals_dept %>%
        filter(!is.na(total_salary_paid),department == input$department, fiscal_year == input$fiscal_year) %>%
        select("total_salary_paid", "gender", "position")
    }

  })
  output$allDat <- renderPlot({
    # Plot for all departments
    if (input$department == "All departments"){
      ggplot(data = liq_all(), aes(x = gender, y= total_salary_paid,color=gender)) +
        geom_jitter(size = 2, width = 0.2, alpha = 0.5) +
        stat_summary(fun.y = mean, geom = "line") +
        stat_summary(fun.y = mean, geom = "point", size = 3) +
        #guides(color=FALSE) +
        theme_bw()
    }
    # Plot for single department
    else {
    ggplot(data = liq_all() %>% filter(gender != "*"),
           aes(x = gender, y= total_salary_paid, color = position, group = position)) +
      geom_jitter(size = 2, width = 0.2, alpha = 0.5) +
      stat_summary(fun.y = mean, geom = "line") +
      stat_summary(fun.y = mean, geom = "point", size = 3) +
      theme_bw()
    }

    })

  output$allDatTab <- renderDataTable({
    dataset <- liq_all()
    dataset %>%
      filter(gender != "*")%>%
      group_by(gender)%>%
      summarize(n = n(), avg_pay = signif(mean(total_salary_paid), 6))
  })

  liq_prof <- reactive({

    # Show all departments and all years
    if (input$department == "All departments" & input$fiscal_year == 'All years'){
      sals_dept_profs %>%
        filter(!is.na(total_salary_paid)) %>%
        select("total_salary_paid","travel_subsistence","gender", "position_simplified","fiscal_year")
    }
    # Show all departments but filter on years
    else if (input$department == "All departments"){
      sals_dept_profs %>%
        filter(!is.na(total_salary_paid),fiscal_year == input$fiscal_year) %>%
        select("total_salary_paid","travel_subsistence","gender", "position_simplified","fiscal_year")
    }
    # Show all years but filter on department
    else if (input$fiscal_year == "All years"){
      sals_dept_profs %>%
        filter(!is.na(total_salary_paid),department == input$department) %>%
        select("total_salary_paid","travel_subsistence","gender", "position_simplified","fiscal_year")
    }
    # Filter on department and year
    else {
      sals_dept_profs %>%
        filter(!is.na(total_salary_paid),department == input$department, fiscal_year == input$fiscal_year) %>%
        select("total_salary_paid","travel_subsistence","gender", "position_simplified","fiscal_year")
    }

    })

  output$prof <- renderPlot({
    ggplot(data = liq_prof(),
           aes(x = gender,
               y = total_salary_paid/1000,
               color = position_simplified,
               group = position_simplified)) +
      geom_jitter(size = 2, width = 0.2, alpha = 0.2) +
      stat_summary(fun.y = mean, geom = "line", size = 2) +
      stat_summary(fun.y = mean, geom = "point", size = 3) +
      theme_bw() +
      labs(x = NULL, y = "Total Salary Paid\nThousands of $")
  })
  output$profTab <- renderDataTable({
    dataset <- liq_prof()
    dataset %>%
      group_by(fiscal_year, gender)%>%
      summarize(n = n(), avg_pay = signif(mean(total_salary_paid), 6))%>%
      tidyr::unite("avg_pay_n", avg_pay, n, sep = " (")%>%
      dplyr::mutate("avg_pay_n" = stringr::str_c(avg_pay_n, ")" , sep = ""))%>%
      tidyr::spread(key = fiscal_year, value = avg_pay_n)

  })

  liq_postdoc<- reactive ({
    sals_dept %>%
      filter(department == input$department)%>%
      filter(grepl('POSTDOC', position)) %>%
      select("total_salary_paid","travel_subsistence","gender", "fiscal_year")
  })
  output$postdoc <- renderPlot({
    ggplot(data = liq_postdoc(),
           aes(x = gender,
               y = total_salary_paid/1000)) +
      geom_jitter(size = 3, width = 0.2, alpha = 0.5, aes(color = gender)) +
      stat_summary(fun.y = mean, geom = "line") +
      stat_summary(fun.y = mean, geom = "point", size = 5) +
      theme_bw()+
      scale_color_manual(values = c("tomato", "dodgerblue2")) +
      labs(x = NULL, y = "Total Salary Paid\nThousands of $") +
      guides(color = F)
  })
  output$postdocTab <- renderDataTable({
    dataset <- liq_postdoc()
    dataset %>%
      group_by(fiscal_year, gender)%>%
      summarize(n = n(), avg_pay = signif(mean(total_salary_paid), 6))%>%
      tidyr::unite("avg_pay_n", avg_pay, n, sep = " (")%>%
      dplyr::mutate("avg_pay_n" = stringr::str_c(avg_pay_n, ")" , sep = ""))%>%
      tidyr::spread(key = fiscal_year, value = avg_pay_n)
  })
}

shinyApp(ui, server)
