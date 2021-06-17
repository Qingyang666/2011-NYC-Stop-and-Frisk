library(tidyverse)
library(ggplot2)
library(ROCR)
library(ranger)
# read in the data set
sqf.data <- read_csv('data/sqf_2011.csv')

# filter data to observations with suspected crime of carrying a weapon 
sqf.data <- sqf.data %>% filter(suspected.crime == 'cpw')

# select variables
sqf.model <- sqf.data %>%
  select(found.weapon, # response variable
         precinct,
         location.housing,
         starts_with("additional."),
         starts_with("stopped.bc."),
         suspect.age, suspect.build, suspect.sex, suspect.height, suspect.weight,
         inside,
         radio.run,
         observation.period,
         day,
         month,
         time.period)

# check for missingness
check.na <- sapply(sqf.model, function(x){sum(is.na(x))})
check.na

# remove all missing values 
sqf.model.complete <- sqf.model %>% filter(complete.cases(sqf.model))
cat('The proportion of removal is', (nrow(sqf.model)-nrow(sqf.model.complete))/nrow(sqf.model))

# look at the dataset
glimpse(sqf.model.complete)

# look at the response variable
table(sqf.model.complete$found.weapon)
# visualize
sqf.model.complete %>% 
  group_by(found.weapon) %>% 
  summarise(num_obs = n()) %>% 
  ungroup() %>%
  ggplot(aes(x = found.weapon, y = num_obs)) +
  geom_bar(stat = 'identity')
# the response variable is imbalanced.

# randomly split data set into training and testing
set.seed(2021)
n <- nrow(sqf.model.complete)
ran.numb <- sample(x = 1:n, size = floor(n*0.8), replace = FALSE)
train.data <- sqf.model.complete[ran.numb,]
test.data <- sqf.model.complete[-ran.numb,]

# data transformation: should transform variables in train and test separately.
train.data <- train.data %>%
  mutate_if(is.character, as.factor) %>%
  mutate_at(c("precinct","time.period"), as.factor)%>%
  mutate_at(c("suspect.age","suspect.height","suspect.weight","observation.period"), scale)

test.data <- test.data %>%
  mutate_if(is.character, as.factor) %>%
  mutate_at(c("precinct","time.period"), as.factor)%>%
  mutate_at(c("suspect.age","suspect.height","suspect.weight","observation.period"), scale)

# build a logistic regression model
mod1 <- glm(found.weapon ~.,data = train.data, family = 'binomial')
print(mod1)

# make prediction on testing data
## type = response tells R to output P(Y=1|X). In our case, it returns the probability of weapon recovery.
test.lr <- test.data %>% 
  mutate(predicted.probability = predict(mod1, test.data, type = 'response'))

# plot ROC and compute AUC score
test.lr.pred <- prediction(test.lr$predicted.probability, test.lr$found.weapon)
test.lr.roc <- performance(test.lr.pred, measure = 'tpr', x.measure = 'fpr')
plot(test.lr.roc)
test.lr.perf <- performance(test.lr.pred, 'auc')
cat('the auc socre for logistic regression model is ', test.lr.perf@y.values[[1]], "\n")

# recall at k% plot data for logistic regression
plot.data1 <- test.lr %>%
  select(found.weapon, predicted.probability) %>%
  arrange(desc(predicted.probability)) %>%
  mutate(numstops = row_number(),
         percent.outcome = cumsum(found.weapon)/sum(found.weapon),
         percent.stops = numstops/n()) %>%
  select(percent.stops,percent.outcome)

# build a random forest model
mod2 <- ranger(formula = found.weapon ~., data = train.data, 
               num.trees = 1000, 
               respect.unordered.factors = TRUE, 
               probability = TRUE)

# make prediction on testing data
test.rf <- test.data %>% 
  mutate(predicted.probability = predict(mod2, data = test.data, type = 'response')$predictions[,2])

# plot ROC curve and compute AUC score
test.rf.pred <- prediction(test.rf$predicted.probability, test.rf$found.weapon)
test.rf.roc <- performance(test.rf.pred, measure = 'tpr', x.measure = 'fpr')
plot(test.rf.roc)
test.rf.perf <- performance(test.rf.pred, 'auc')
cat('the auc score for a random forest model is ', test.rf.perf@y.values[[1]], "\n") 

# recall at k% plot data for random forest
plot.data2 <- test.rf %>%
  select(found.weapon, predicted.probability) %>%
  arrange(desc(predicted.probability)) %>%
  mutate(numstops = row_number(),
         percent.outcome = cumsum(found.weapon)/sum(found.weapon),
         percent.stops = numstops/n()) %>%
  select(percent.stops,percent.outcome)

# recall at k% plot: blue: logistic regression, red: random forest
theme_set(theme_bw())
colors <- c("Logistic Regression"="blue", "Random Forest"="red")
p <- ggplot()+
  geom_line(data = plot.data1,
            aes(x = percent.stops, y = percent.outcome, color = "Logistic Regression"), size=1.5)+
  geom_line(data = plot.data2,
            aes(x = percent.stops, y = percent.outcome, color = "Random Forest"), size=1.5)+
  labs(x = "Percent of stops",
       y = "Percent of weapon found",
       color = "Legend")+
  scale_x_log10(limits = c(0.003,1), 
                breaks = c(0.003, 0.01, 0.03, 0.1, 0.3, 1),
                labels = c('0.3%', '1%', '3%', '10%', '30%', '100%'))+
  scale_y_continuous(limits = c(0,1),
                     labels = scales::percent)+
  scale_color_manual(values = colors)
p
