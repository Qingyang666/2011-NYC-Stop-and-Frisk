## 2011 NYC SQF ANALYSIS

### Data Source
The link of NYC Stop, Question and Frisk Data is here(https://www1.nyc.gov/site/nypd/stats/reports-analysis/stopfrisk.page). For each stop that was made by NYPD, the police officer should fill out a worksheet called Unified Form 250 to record the details of the stop. All the information in each year's data is coverted from the Unified Form 250, aka UF-250. In this project, we analyzed data in year 2011. The dataset contains over 680k observations and 112 columns.

### Process
  - Data Preprocessing Using R
  - Data Visualization By Building Interactive Dashboard Using Tableau
  - Statistical Modelling and Model Evaluation Using R
 
#### Data Preprocessing
  - Rename and Recode varaibles with Y/N into TRUE(1) and FALSE(0)
  - Recode categorical variables into human readable
  - Deal with date and time variables
    - Generate weekday as a variable: Monday, Tuesday, etc
    - Generate month as a variable: January, Feburary, etc
    - Extract hour from timestamp and perform binning(6 bins) 
  - Deal with age variable
    - restrict suspect age between 10 to 80
  - Deal with weight variable
    - set suspect weight over 700 lbs into NA for further cleansing
  - Deal with Height variable
    - Combine height in feet and height in inches into one variable
  - Create a new variable as found.weapon
    - pistol, rifle, assult weapon, machinegun, knife, other weapon
  - Drop irrelevant and bad coded variables

#### Interactive Dashboard
Here is the link for my interactive dashboard:
(https://public.tableau.com/app/profile/qingyang.li1140/viz/2011NYCStopandFriskDashboard/Dashboard1)
![alt text](https://github.com/Qingyang666/2011-NYC-Stop-and-Frisk/blob/main/figures/Screen%20Shot%202021-06-17%20at%203.29.47%20PM.png)

#### Model and Evaluation
Predict weapon recovery, which is whether or not a weapon was found from the suspect. 
  - Filter records with suspected crime = cpw 
  - Select specific variables for model building 
    - reason for stop (contains 10 different reasons)
    - addition circumstances (contains 10 different circumstances)
    - demographics variables(age, build, sex, height, weight)
    - date and time varaibles(time in hour, weekday, month)
    - others
      - precinct
      - whether the stop occurred in transit, housing, or on the street
      - whether the stop occurred inside
      - whether the stop was the result of a radio call
      - length of observation period
Since the data is imbalanced, I decided to use AUC score instead of Accuracy
  - Logistic Regression with AUC score of 0.83 approximately
  - Random Forest with AUC score of 0.84 approximately
Below is the Recall at k% plot for both models
![alt text](https://github.com/Qingyang666/2011-NYC-Stop-and-Frisk/blob/main/figures/recall_at_k.png)
