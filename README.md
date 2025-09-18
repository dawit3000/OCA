**OCA (Overload Compensation App)** is a Shiny web application designed
to calculate fair instructor pay for overload teaching assignments in
higher education. It applies institutional policy while offering
strategic flexibility — allowing administrators to favor cost-saving,
faculty retention, or a balanced approach.

# 🔑 Key Features/ How it works

- Upload your institution’s teaching schedule: a `.csv` file with
  scheduled courses, instructor names, credit hours, and enrollments.
  This file could be from
  - a local data folder, or  
  - a URL pointing to such file
- The uploaded file must include the following exact column names as
  minimal requirement:
  - INSTRUCTOR — Instructor name
  - SUBJ — Name of course (e.g. MATH 1111 or ENGL 2111-02)
  - HRS — Credit hours
  - ENRLD — Enrollment
- Optionally filter courses by:
  - Subject
  - Instructor
  - College
  - Department
  - Program
- Set Institutional Policy Parameters:
  - Pay rate per qualified credit hour
  - Regular teaching load (in credit hours)
  - Minimum and maximum enrollment thresholds for proration
    - For your institution has no proration policy,i.e., if it pays full
      for low-enrolled courses, set both L and U to 0.
- Select a compensation strategy via slider: use the slider to choose
  between institution-favored, instructor-favored, or blended strategy.
  - **Favor Institution** – prioritizes cost savings
  - **Favor Faculty** – prioritizes fairness
  - **Blend** – weighted average between the two extremes
- Option to compare all strategies in the output. The app calculates and
  displays instructor-level pay by strategy, with comparison charts and
  summaries.
- Visualize compensation differences with a comparison chart

# 📸 Screenshot – UI for Left Panel

<br>

<figure>
<img src="pics/oca_dashboard.png" alt="OCA Dashboard" />
<figcaption aria-hidden="true">OCA Dashboard</figcaption>
</figure>

# 📸 Screenshot – Strategy Output Comparison

<br>

<figure>
<img src="pics/oca_output_right.png" alt="OCA Output Chart" />
<figcaption aria-hidden="true">OCA Output Chart</figcaption>
</figure>

<br>

# 🖥️ Deployment

The OCA App is now live hosted at shinyapps.io:  
👉 [Launch OCA](https://aberra.shinyapps.io/OCA_shinyApp/)

# 📁 Sample Data

Try the app using these example schedules:

- [`sample_schedule.csv`](https://raw.githubusercontent.com/dawit3000/OCA/main/sample_schedule.csv)  
- [`Johnson_n_Smith_schedule.csv`](https://raw.githubusercontent.com/dawit3000/OCA/main/Johnson_n_smith_schedule.csv)

# 🧰 Powered By

- [`catool`](https://github.com/dawit3000/catool) – R package for
  calculating overload pay based on institutional policy
- [`shiny`](https://shiny.posit.co/) – R package for building
  interactive web applications

# 📄 Related Articles

- **“catool: An R Package for Automating Fair Compensation in Higher
  Education”**  
  *(Submitted to The R Journal)*

- **“OCA: A Shiny Web Application for Transparent Overload Compensation
  in Higher Education”**  
  *(In preparation for submission to SoftwareX)*

# 💻 Note:

OCA assumes a basic familiarity with faculty overload policies. For new
users, future versions may include tooltips and in-app help. In the
meantime, this guide provides clarifications on how proration, pay
rates, and thresholds are applied within the app.

# 💻 Run Locally

’

``` r
# Install required packages
install.packages(c("shiny", "catool", "dplyr", "readr", "ggplot2", "DT", "shinyWidgets"))

# Run the app
library(shiny)
runApp("path/to/OCA_shinyApp")
---
```
