# OCA: Transparent Overload Compensation App

**OCA (Overload Compensation App)** is a Shiny web application designed
to calculate fair instructor pay for overload teaching assignments in
higher education. It applies institutional policies and offers strategic
flexibility — allowing administrators to favor cost-saving, faculty
retention, or a blend of both.

## 🔑 Key Features

- Upload a teaching schedule in `.csv` format from a loacal data folder
  or a url to such file
- Optionally, filter courses by patterns of:
  - Subject
  - Instructors
  - College
  - Department
  - Program -Enter Institutional compensation policies such as
  - Pay Rate per Credit Hour
  - Regular Teaching Load
  - Minimum Enrollment for Proration(L)
  - Maximum Enrollment for Proration(U)
    - if none, choose L = U = 1 so that no proration (extreme case to be
      checked).  
- Choose a compensation strategy using a slider:
  - **Favor Institution** (minimize pay)
  - **Favor Faculty** (maximize fairness)
  - **Blend** between the two with a user-defined approach (weighed mean
    approach).
- An option to Compare All Strategies in the output
- Show Comparison Chart to isualize instructor compensation totals
  across strategies

## 🖥️ Try the Live App

[Launch OCA App](https://aberra.shinyapps.io/OCA_shinyApp/)

## 📁 Sample Data

Try the app using this example schedule:

- [Download
  sample_schedule.csv](https://raw.githubusercontent.com/dawit3000/OCA/main/sample_schedule.csv)
- [Download
  Johnson_n_Smith_schedule.csv](https://raw.githubusercontent.com/dawit3000/OCA/main/Johnson_n_smith_schedule.csv)

## 🧰 Powered By

- `catool` – an R package for calculating overload pay based on credit
  hours, enrollment, and institutional rules
- `shiny` – R package for web applications

## 📄 Related Articles

- **“Automating Fairness: An R Package for Calculating Overload
  Compensation in Higher Education”** (submitted to *The R Journal*)
- **“OCA: A Shiny Web Application for Transparent Overload Compensation
  in Higher Education”** (in preparation for *SoftwareX*)

## 💻 Run Locally

\`\`\`r \# If needed, install dependencies install.packages(c(“shiny”,
“dplyr”, “readr”, “ggplot2”, “DT”, “shinyWidgets”)) \#
install.packages(“catool”) \# from CRAN or GitHub

# Run the app

library(shiny) runApp(“path/to/OCA_shinyApp”)
