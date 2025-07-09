library(shiny)
library(shinyWidgets)
library(readr)
library(dplyr)
library(catool)
library(ggplot2)
library(DT)

ui <- fluidPage(
  titlePanel("OCA: Transparent Overload Compensation App"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload Schedule CSV", accept = ".csv"),
      textInput("csv_url", "Or enter URL to CSV file:",
                placeholder = "https://raw.githubusercontent.com/youruser/yourrepo/main/schedule.csv"),
      
      uiOutput("unique_instructors"),  # Instructor filter
      
      textInput("subj_pattern", "Subject Pattern (optional, e.g., MATH|CSCI)", value = ""),
      textInput("instr_pattern", "Instructor Pattern (optional, e.g., Smith|Lee)", value = ""),
      textInput("college_pattern", "College Pattern (optional, e.g., Arts|Science)", value = ""),
      textInput("department_pattern", "Department Pattern (optional, e.g., Math|Biology)", value = ""),
      textInput("program_pattern", "Program Pattern (optional, e.g., Computer)", value = ""),
      
      numericInput("rate", "Pay Rate per Credit Hour", value = 2500 / 3, step = 50),
      numericInput("reg", "Regular Teaching Load", value = 12, min = 1),
      numericInput("L", "Minimum Enrollment for Proration (L)", value = 4, min = 0),
      numericInput("U", "Maximum Enrollment for Proration (U)", value = 9, min = 0),
      
      sliderInput("favor_weight", "Strategy (1 = Favor Institution, 0 = Favor Faculty)",
                  min = 0, max = 1, value = 1, step = 0.05),
      
      checkboxInput("compare", "Compare All Strategies", value = FALSE),
      checkboxInput("show_plot", "Show Comparison Chart", value = FALSE),
      
      uiOutput("column_selector"),
      downloadButton("download", "Download Current Table")
    ),
    
    mainPanel(
      conditionalPanel(
        condition = "input.compare == true",
        tabsetPanel(id = "compare_tabs",
                    tabPanel("Favor Institution", DTOutput("table_inst")),
                    tabPanel("Blend", DTOutput("table_blend")),
                    tabPanel("Favor Instructor", DTOutput("table_instr"))
        )
      ),
      conditionalPanel(
        condition = "input.compare == false",
        DTOutput("result_table")
      ),
      conditionalPanel(
        condition = "input.show_plot == true",
        plotOutput("pay_plot")
      )
    )
  )
)

server <- function(input, output, session) {
  uploaded_data <- reactive({
    if (!is.null(input$file)) {
      read_csv(input$file$datapath, show_col_types = FALSE)
    } else if (nzchar(input$csv_url)) {
      tryCatch(read_csv(input$csv_url, show_col_types = FALSE),
               error = function(e) {
                 showNotification("Error reading CSV from URL.", type = "error")
                 return(NULL)
               })
    } else {
      return(NULL)
    }
  })
  
  output$unique_instructors <- renderUI({
    df <- uploaded_data()
    req(df)
    
    colname_instr <- names(df)[toupper(names(df)) %in% c("INSTR", "INSTRUCTOR")]
    if (length(colname_instr) == 0) return(NULL)
    
    instructors <- sort(unique(df[[colname_instr[1]]]))
    
    pickerInput("instructor_select", "Select Instructors(optional):",
                choices = instructors,
                selected = NULL,
                multiple = TRUE,
                options = list(
                  `actions-box` = TRUE,
                  `live-search` = TRUE,
                  `selected-text-format` = "count > 3"
                ))
  })
  
  filtered_data <- reactive({
    df <- uploaded_data()
    req(df)
    
    required <- c("SUBJ", "ENRLD", "HRS")
    missing <- setdiff(required, names(df))
    if (length(missing) > 0) {
      showNotification(paste("Missing required column(s):", paste(missing, collapse = ", ")), type = "error")
      return(NULL)
    }
    
    catool::filter_schedule(
      schedule = df,
      subject_pattern = if (nzchar(input$subj_pattern)) input$subj_pattern else NULL,
      instructor_pattern = if (!is.null(input$instructor_select) && length(input$instructor_select) > 0) {
        paste(input$instructor_select, collapse = "|")
      } else if (nzchar(input$instr_pattern)) {
        input$instr_pattern
      } else NULL,
      college_pattern    = if (nzchar(input$college_pattern)) input$college_pattern else NULL,
      department_pattern = if (nzchar(input$department_pattern)) input$department_pattern else NULL,
      program_pattern    = if (nzchar(input$program_pattern)) input$program_pattern else NULL
    )
  })
  
  comp_results <- reactive({
    df <- filtered_data()
    req(df)
    
    w <- input$favor_weight
    
    df_inst <- catool::ol_comp_summary(df, rate_per_cr = input$rate, reg_load = input$reg,
                                       favor_institution = TRUE, L = input$L, U = input$U)
    
    df_instr <- catool::ol_comp_summary(df, rate_per_cr = input$rate, reg_load = input$reg,
                                        favor_institution = FALSE, L = input$L, U = input$U)
    
    if (!"RowNo" %in% names(uploaded_data())) {
      df_inst <- df_inst %>% select(-any_of("RowNo"))
      df_instr <- df_instr %>% select(-any_of("RowNo"))
    }
    
    blend_cols <- c("QHRS", "PAY")
    blend_cols <- intersect(blend_cols, names(df_inst))
    df_blend <- df_inst
    
    for (col in blend_cols) {
      i_vals <- suppressWarnings(as.numeric(df_inst[[col]]))
      f_vals <- suppressWarnings(as.numeric(df_instr[[col]]))
      avg_vals <- round(w * i_vals + (1 - w) * f_vals, 2)
      df_blend[[col]] <- ifelse(is.na(avg_vals), "", as.character(avg_vals))
    }
    
    df_blend$TYPE <- ifelse(
      df_inst$TYPE == "TOT", "TOT",
      ifelse(
        df_blend$QHRS != "0" & df_blend$PAY != "" &
          suppressWarnings(as.numeric(df_blend$PAY)) > 0 &
          df_inst$ENRLD >= input$L & df_inst$ENRLD <= input$U,
        "PRO",
        ifelse(
          df_blend$QHRS != "0" & df_blend$PAY != "" &
            suppressWarnings(as.numeric(df_blend$PAY)) >= input$rate,
          "UNPRO",
          ""
        )
      )
    )
    
    format_dollar <- function(x) {
      if (is.na(x) || x == "") return("")
      x <- suppressWarnings(as.numeric(x))
      if (is.na(x)) return("")
      formatC(x, format = "f", big.mark = ",", digits = 2)
    }
    
    update_summary <- function(df) {
      if (!"SUMMARY" %in% names(df)) {
        df$SUMMARY <- ""
      }
      tot_rows <- which(df$TYPE == "TOT")
      for (idx in tot_rows) {
        instructor <- df$INSTR[idx - 1] %||% ""
        instructor_rows <- which(df$INSTR == instructor & df$TYPE != "TOT")
        qhrs_val <- suppressWarnings(sum(as.numeric(df$QHRS[instructor_rows]), na.rm = TRUE))
        qhrs <- if (!is.na(qhrs_val)) as.character(qhrs_val) else ""
        pay <- format_dollar(df$PAY[idx])
        rate <- format_dollar(input$rate)
        
        df$SUMMARY[idx]     <- paste0("INSTRUCTOR: ", instructor)
        df$SUMMARY[idx + 1] <- paste0("Over ", input$reg, " QHRS: ", qhrs)
        df$SUMMARY[idx + 2] <- paste0("Overload Pay Rate: $", rate)
        df$SUMMARY[idx + 3] <- paste0("Total Overload: $", pay)
        df$SUMMARY[idx + 4] <- "Note: ENRLD<U+1 PRO or NO"
      }
      df
    }
    
    df_blend <- update_summary(df_blend)
    df_inst  <- update_summary(df_inst)
    df_instr <- update_summary(df_instr)
    
    list(instr = df_instr, inst = df_inst, blend = df_blend)
  })
  
  output$column_selector <- renderUI({
    df <- comp_results()$blend
    req(df)
    selectizeInput("columns", "Select Columns for Output:",
                   choices = names(df), selected = names(df), multiple = TRUE,
                   options = list(plugins = list('remove_button')))
  })
  
  render_dt_table <- function(df) {
    datatable(
      df,
      options = list(scrollX = TRUE, scrollY = "600px", paging = FALSE, dom = 'ftip'),
      rownames = FALSE,
      class = "stripe hover nowrap"
    )
  }
  
  output$result_table <- renderDT({
    df <- comp_results()$blend
    req(df)
    if (!is.null(input$columns)) {
      df <- df[, input$columns, drop = FALSE]
    }
    render_dt_table(df)
  })
  
  output$table_instr <- renderDT({
    df <- comp_results()$instr
    if (!is.null(input$columns)) {
      df <- df[, input$columns, drop = FALSE]
    }
    render_dt_table(df)
  })
  
  output$table_inst <- renderDT({
    df <- comp_results()$inst
    if (!is.null(input$columns)) {
      df <- df[, input$columns, drop = FALSE]
    }
    render_dt_table(df)
  })
  
  output$table_blend <- renderDT({
    df <- comp_results()$blend
    if (!is.null(input$columns)) {
      df <- df[, input$columns, drop = FALSE]
    }
    render_dt_table(df)
  })
  
  output$pay_plot <- renderPlot({
    res <- comp_results()
    w <- input$favor_weight
    
    total_pay <- function(df) {
      df_filtered <- df[df$TYPE == "TOT", , drop = FALSE]
      suppressWarnings(sum(as.numeric(df_filtered$PAY), na.rm = TRUE))
    }
    
    strategy_labels <- c("Institution-Favored", paste0("Blend (", round(w, 2), ")"), "Instructor-Favored")
    df_plot <- data.frame(
      Strategy = factor(strategy_labels, levels = strategy_labels),
      TotalPay = c(total_pay(res$inst), total_pay(res$blend), total_pay(res$instr))
    )
    
    x_vals <- c(1, 2, 3)
    y_vals <- df_plot$TotalPay
    curve_df <- data.frame(x = x_vals, y = y_vals)
    smooth_curve <- stats::spline(curve_df$x, curve_df$y, n = 100, method = "natural")
    curve_data <- data.frame(x = smooth_curve$x, y = smooth_curve$y)
    
    ggplot(df_plot, aes(x = Strategy, y = TotalPay, fill = Strategy)) +
      geom_col(width = 0.6, show.legend = FALSE) +
      geom_line(data = curve_data, aes(x = x, y = y), inherit.aes = FALSE,
                color = "black", linetype = "dashed", linewidth = 1) +
      labs(title = "Total Overload Compensation", y = "Amount ($)", x = "") +
      theme_minimal() +
      geom_text(aes(label = round(TotalPay, 2)), vjust = -0.5) +
      theme(axis.text.x = element_text(size = 14),
            axis.title = element_text(size = 16),
            plot.title = element_text(size = 18, face = "bold"))
  })
  
  output$download <- downloadHandler(
    filename = function() "overload_compensation_output.csv",
    content = function(file) {
      df <- comp_results()$blend
      if (!is.null(input$columns)) {
        df <- df[, input$columns, drop = FALSE]
      }
      write.csv(df, file, row.names = FALSE, na = "")
    }
  )
}

shinyApp(ui = ui, server = server)
