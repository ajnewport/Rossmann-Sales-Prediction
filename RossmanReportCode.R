library(dplyr)
library(lubridate)
library(ggplot2)
library(corrplot)
library(randomForest)
library(caret)
library(fastDummies)

# Stores.csv file

data= read.csv("store1.csv")
summary(data)
# interesting observations:
# storetypes - imbalanced, i.e b=17 (smallest), a=602 (largest)
# assortment: a,c similar counts, b=9.
# compopensinceyear=1900, also there's 1961 and 1990 after that. need more info

point1900 <- data[which(data$CompetitionOpenSinceYear==1900),]

NA_per_col = colSums(is.na(data))
#3 in competitionDistance, 354 in CompOpenSinceMonth, 354 in CompOpenSinceYear, 
#544 in Promo2SinceWeek, 544 in Promo2SinceYear

temp <- sapply(data, is.character) 
data[temp] <- lapply(data[temp], as.factor) # changing datatype to recognise levels 
levels(data$PromoInterval)


# Train.csv file
train = read.csv("train1.csv")
summary(train)
sum(is.na(train)) # no na values detected.

na_dist <- data[is.na(data$CompetitionDistance), ]

# Test.csv file
test = read.csv("test1.csv")

# Data Quality Evaluation
# Accuracy - see Outliers
# Completeness - See vars
# Uniqueness - check for duplicates
dupes <- sum(duplicated(data))
print(dupes)
dupes2 <- sum(duplicated(train))
print(dupes2)
dupes3 <- sum(duplicated(test))
print(dupes3)
# all 0, to be expected.
# Consistency
# detect any negative values.
negative_values_stores <- data %>% 
  select_if(~ is.numeric(.) && any(. < 0))
print(negative_values_stores)
negative_values_train <- train %>% 
  select_if(~ is.numeric(.) && any(. < 0))
print(negative_values_train)
negative_values_test <- test %>% 
  select_if(~ is.numeric(.) && any(. < 0))
print(negative_values_train)
# closed stores should have no sales, this rings true.
closed_stores <- train[train$Open == 0, ]

# Checking the nature of Missingness

data_grouped <- data %>% 
  group_by(StoreType)


missingness_summary <- data_grouped %>%
  summarise(across(c(CompetitionDistance, CompetitionOpenSinceMonth, 
                     CompetitionOpenSinceYear, Promo2SinceWeek, Promo2SinceYear),
                   ~ mean(is.na(.))))


missingness_summary_long <- tidyr::pivot_longer(missingness_summary,
                                                cols = -StoreType,
                                                names_to = "Variable",
                                                values_to = "Missingness")


ggplot(missingness_summary_long, aes(x = StoreType, y = Missingness, fill = Variable)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Missingness by Store Type",
       x = "Store Type",
       y = "Proportion of Missing Values",
       fill = "Variable") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

data_grouped <- data %>% 
  group_by(Assortment)


missingness_summary <- data_grouped %>%
  summarise(across(c(CompetitionDistance, CompetitionOpenSinceMonth, 
                     CompetitionOpenSinceYear, Promo2SinceWeek, Promo2SinceYear),
                   ~ mean(is.na(.))))


missingness_summary2 <- tidyr::pivot_longer(missingness_summary,
                                                cols = -Assortment,
                                                names_to = "Variable",
                                                values_to = "Missingness")

ggplot(missingness_summary2, aes(x = Assortment, y = Missingness, fill = Variable)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Missingness by Assortment",
       x = "Assortment",
       y = "Proportion of Missing Values",
       fill = "Variable") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



# Data Linkage & Data/Variable Transformation

data <- merge(train, data, by = "Store")
print(head(data))

#Checking if the info on StateHoliday is necessary.
filterd <- subset(data, StateHoliday != "0")
stateholiday <- aggregate(Sales ~ StateHoliday, data = filterd, sum)
ggplot(stateholiday, aes(x = StateHoliday, y = Sales)) +
  geom_bar(stat = "identity", fill = "chartreuse4") +
  labs(title = "Number of Sales by Type of State Holiday", x = "State Holiday", y = "Number of Sales") +
  scale_y_continuous(labels = scales::comma_format())

# median imputation
data$CompetitionDistance[is.na(data$CompetitionDistance)] <- median(data$CompetitionDistance, na.rm=TRUE)
# mode imputation for CompYear and CompMonth
mode_function<- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
compYear <- mode_function(data$CompetitionOpenSinceYear, na.rm = TRUE)
data$CompetitionOpenSinceYear[is.na(data$CompetitionOpenSinceYear)] <- compYear
compMonth <- mode(data$CompetitionOpenSinceMonth, na.rm = TRUE)
data$CompetitionOpenSinceMonth[is.na(data$CompetitionOpenSinceMonth)] <- compMonth

# avg walking distance boolean
data$Within1hrWalk <- ifelse(data$CompetitionDistance <= 5000, 1, 0)
breaks <- c(0, 2000, 5000, Inf)
# new var with three levels based on CompetitionDistance
data$CompetitionDistanceLevel <- cut(data$CompetitionDistance, breaks = breaks, labels = c("Low", "Medium", "High"), include.lowest = TRUE)

# extracting features from date
data$Date <- dmy(data$Date)
data$Month <- month(data$Date)
data$DayNumber <- day(data$Date)
data$Week <- week(data$Date)
data$Week <- ifelse(data$Week == 53, 52, data$Week)
data$Year <- year(data$Date)

#sorting out promo2
# Replace Promo2SinceYear with 0 where Promo2 is 0
data$Promo2SinceYear[data$Promo2 == 0] <- 0

# Replace Promo2SinceWeek with 0 where Promo2 is 0
data$Promo2SinceWeek[data$Promo2 == 0] <- 0

# No. of months competition has been open in total.
data$CompetitionTotalMonths <- ((data$Year - data$CompetitionOpenSinceYear) * 12 +
  (data$Month) - data$CompetitionOpenSinceMonth)
# No. of months promo2 has been active in total.
data$Promo2TotalMonths <- round(12 * (data$Year - data$Promo2SinceYear) + 
  (data$Week - data$Promo2SinceWeek) / 4.0)


# change labelling for var Assortment
data$Assortment = as.factor(data$Assortment)
levels(data$Assortment)
data$Assortment <- factor(data$Assortment, levels = c("a", "b", "c"), 
                        labels = c("Basic", "Extra", "Extended"))

# Combining School and State holiday, renaming (may not be added)
data <- data %>%
  mutate(Holiday = ifelse(data$StateHoliday == "a", "State Holiday", 
                          ifelse(data$StateHoliday == "b", "Easter Holiday",
                                 ifelse(data$StateHoliday == "c", "Christmas", 
                                        ifelse(data$SchoolHoliday == 1, "School Holiday", "No Holiday")))))

# Renaming days of the week (may not be added)
data <- data %>%
  mutate(DayofWeek = ifelse(data$DayOfWeek == "1", "Monday", 
                          ifelse(data$DayOfWeek == "2", "Tuesday",
                                 ifelse(data$DayOfWeek == "3", "Wednesday", 
                                        ifelse(data$DayOfWeek == "4", "Thursday",
                                               ifelse(data$DayOfWeek == "5", "Friday",
                                                      ifelse(data$DayOfWeek == "6", "Saturday", "Sunday")))))))


# Test data preprocessing !!!

start<- as.Date("2015-08-01")
end<- as.Date("2015-09-17")
num_days <- end - start + 1 
41088/48 # 856 unique stores out of 1115
teststores <- as.numeric(as.character(unique(test$Store)))

# Remove irrelevant data in training using teststores values
train <- train[train$Store %in% teststores,]
# reduced by about 25%. Yippee

# (EDA) plots

ggplot(data, aes(x = factor(DayOfWeek), y = Sales)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Sales vs Day of Week", x = "Day of Week", y = "Sales")



# removing closed entries
train[which(train$Open==0),]
which(train$Open==0 && (train$Sales>0 | train$Customers>0)) # just to check that it IS the case that when a store is closed there no sales/customers!
train <- train[train$Open !=0,]

# Closed Days
closed_days <- data[which(data$Open==0),]
summary(closed_days)
closedperstore <- table(data$Store[data$Open==0])
closedperday <- table(closed_days$DayOfWeek)
barplot(closedperday, 
        main = "Number of Closed Days vs. Day of Week",
        xlab = "Day of Week",
        ylab = "Number of Closed Days",
        border  = "black",
        col = "purple4",
        names.arg = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))


ggplot(data, aes(x = CompetitionOpenSinceMonth)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  labs(title = "Distribution of CompetitionOpenSinceMonth", x = "CompetitionOpenSinceMonth", y = "Frequency")

ggplot(data, aes(x = CompetitionOpenSinceYear)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  labs(title = "Distribution of CompetitionOpenSinceYear", x = "CompetitionOpenSinceYear", y = "Frequency")


# dummy vars - need to check when to do this 
# probs after eda, before modelling
# 

# experimental corrplot
numeric_data <- data[, sapply(data, is.numeric)]
correlation_matrix <- cor(numeric_data, use = "complete.obs")  # "complete.obs" removes rows with NA values

corrplot(correlation_matrix, method = "square")

combined_data <- data
combined_data$StoreType <- as.factor(combined_data$StoreType)
combined_data$Assortment <- as.factor(combined_data$Assortment)
combined_data$StateHoliday <- as.factor(combined_data$StateHoliday)
combined_data$PromoInterval <- as.factor(combined_data$PromoInterval)

# need to explicitly convert these factors to numeric codes (integer values)
combined_data$StoreType <- as.integer(combined_data$StoreType) - 1 # Subtract 1 to start at 0, like LabelEncoder
combined_data$Assortment <- as.integer(combined_data$Assortment) - 1
combined_data$StateHoliday <- as.integer(combined_data$StateHoliday) - 1
combined_data$PromoInterval <- as.integer(combined_data$PromoInterval) - 1

numeric_data <- combined_data[, sapply(data, is.numeric)]
numeric_data <- na.omit(numeric_data)
constant_columns <- sapply(numeric_data, function(x) sd(x, na.rm = TRUE) == 0)
numeric_data_clean <- numeric_data[, !constant_columns]
correlation_matrix <- cor(numeric_data_clean)  # "complete.obs" removes rows with NA values
correlation_matrix <- cor(numeric_data)
corrplot(correlation_matrix, method = "color", col = palette, addCoef.col = 'black', tl.cex=0.7, number.cex=0.7, tl.col='black')
palette = colorRampPalette(c("forestgreen", "white", "red"))(20)
heatmap(x = correlation_matrix, col = palette, symm = TRUE)



# Creating dummies for categorical vars
dummies <- dummyVars("~ .", data=data, fullRank = FALSE)
data_transformed <- predict(dummies, newdata = data)
data_transformed <- as.data.frame(data_transformed)
# MODEL (RF)

n = nrow(data_transformed)
trainIndex = sample(1:n, size = round(0.7*n), replace=F)
traindata = data_transformed[trainIndex ,]
testdata = data_transformed[-trainIndex ,]
traindata2 = traindata[,-c("Sales")]

set.seed(123)
n = nrow(data)
trainIndex = sample(1:n, size = round(0.7*n), replace=F)
traindata = data[trainIndex ,]
testdata = data[-trainIndex,]
trainsales <- traindata[,-c(3,4)]
traincustomers <- traindata[,-c(3,5)]
model1 <- randomForest(Sales ~ ., data = traindata[-c(Sales,Customers)], importance = T)

trainIndex <- createDataPartition(data$StateHoliday, p = 0.7, list = FALSE)

# Create training and testing sets using the indices
traindata <- data[trainIndex, ]
testdata <- data[-trainIndex, ]

set.seed(123)
index = sample(2,nrow(data),replace = TRUE, prob=c(0.7,0.3))
train70 <- data[index==1,]
train30 <- data[index==2,]

model1 <- lm(Sales ~., data=train70[-c(3)])

storelm <- function(storeNumber) {
  store <- data[data$Store == storeNumber,]  # a store is selected
  shuffledIndices <- sample(nrow(store))  # the data for the store are shuffled
  store$Prediction <- 0
  z <- nrow(store)
  for (i in 1:10) {    # 10-fold cross-validation
    sampleIndex <- floor(1+0.1*(i-1)*z):(0.1*i*z)  # 10 % of all data rows is selected
    test <- store[shuffledIndices[sampleIndex],]  # it is used as test set
    train <- store[shuffledIndices[-sampleIndex],]  # the rest is used as training set
    modell <- lm(Sales ~ Promo + SchoolHoliday + DayOfWeek + as.factor(Year) + as.factor(Month) + as.factor(DayNumber) + as.factor(Week), train)  # a linear model is fitted to the training set
    store[shuffledIndices[sampleIndex],]$Prediction <- predict(modell,test) # predictions are generated for the test set based on the model
  }
  
  print(paste("Prediction for 13/6/1: ", store[store$DateYear == 13 & store$DateMonth == 6 & store$DateDay == 1,]$Prediction))
  
  ### For some reason that is not clear to me, the linear models generate very inaccurate predictions (usually sales above 100,000) for June 1, 2013 for all stores. I work around this problem by falling back to a less specific prediction for that date: the mean of all predictions generated for the current store.
  
  store[store$DateYear == 13 & store$DateMonth == 6 & store$DateDay == 1,]$Prediction <- mean(store$Prediction)
  
  print(paste("Training error: ", summary.lm(modell)[6]))  # this is the training error of the model that was fitted last
  
  sqrt(mean((store$Sales-store$Prediction)^2))
}

paste("RMSE: ", storelm(1))


set.seed(100)  # setting seed to reproduce results of random sampling
trainingRowIndex <- sample(1:nrow(data), 0.75*nrow(data))  # row indices for training data
trainingData <- data[trainingRowIndex, ]  # model training data
testData  <- data[-trainingRowIndex, ]  
fit <- lm(Sales ~ Customers + CompetitionDistance + Promo2+ CompetitionDistance + PromoDuration, data=trainingData)


