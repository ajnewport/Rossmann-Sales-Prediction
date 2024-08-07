# 1 Introduction

Sales forecasting is necessary for commercial businesses to make future decisions based on demand. In this report, the data collected are from Rossmann, a pharmaceutical store chain in Europe over the course of two and a half years. It consists of 1,115 franchises located across Germany. The main objective is to preprocess the data in such a way that it is reliable enough to conduct an exploratory analysis. This involves multiple steps, which include assessing the data quality, data cleaning, data transformation, and finally, reducing the data. This is preceded by choosing and constructing a model that predicts 6 weeks of daily sales, of which the accuracy is appropriately evaluated.

The data is open-source and can be found at: https://www.kaggle.com/c/rossmann-store-sales/data 

# 2 Description of the Data

The data are separated into three datasets, called “store.csv”, “train.csv”, and “test.csv”. We have the following variables, as described in the Kaggle URL:

Most of the fields are self-explanatory. The following are descriptions for those that aren't.

Id - a unique identification representing a (Store, Date) duple within the test set

Store - a unique Id for each store

Sales - the turnover for any given day (our dependent variable)

Customers - the number of customers on a given day

Open - an indicator for whether the store was open: 0 = closed, 1 = open

StateHoliday - indicates a state holiday. Normally all stores, with few exceptions, are closed on state holidays. Note that all schools are closed on public holidays and weekends. a = public holiday, b = Easter holiday, c = Christmas, 0 = None

SchoolHoliday - indicates if the (Store, Date) was affected by the closure of public schools

StoreType - differentiates between 4 different store models: a, b, c, d

Assortment - describes an assortment level: a = basic, b = extra, c = extended

CompetitionDistance - distance in meters to the nearest competitor store

CompetitionOpenSince[Month/Year] - gives the approximate year and month of the time the nearest competitor was opened

Promo - indicates whether a store is running a promo on that day

Promo2 - Promo2 is a continuing and consecutive promotion for some stores: 0 = store is not participating, 1 = store is participating

Promo2Since[Year/Week] - describes the year and calendar week when the store started participating in Promo2

PromoInterval - describes the consecutive intervals Promo2 is started, naming the months the promotion is started anew. E.g. "Feb,May,Aug,Nov" means each round starts in February, May, August, November of any given year for that store

To summarize, “store.csv” contains the information for each Rossmann franchise, and thus has 1,115 observations; “train.csv” and “test.csv” both contain the sales data each day from 01/01/2013 to 31/07/2015, except for “test.csv” that Sales and Customers are unknown for the period of 01/08/2015 to 17/09/2015. These variables will be referenced throughout the report.

# 3 Data Preprocessing

The importance of preprocessed data becomes apparent when attempting to train a model. Training on "dirty" data usually results in improper and inaccurate results. This report adopts a systematic approach to handling the Rossmann data.

## 3.1 Data Quality

We assess the data quality based on the dimensions defined by the Government Data Quality Hub [[1]](#references). The Rossmann data represents a real-world scenario of 1,115 stores, with their respective customers and sales, so we assess the accuracy of the information based on these given circumstances.

In terms of completeness, some variables' explanations appear vague; for example, "StoreType" has levels a, b, c, d, which signify the store models, but the descriptions of these models are not defined. This lack of information could be crucial in analysis—if a store model performs better monetarily, it could be due to factors other than the model itself. Regarding uniqueness, there are no duplicates in all three datasets, facilitating their combination. Consistency requires data values not to contradict each other, and all values or levels must be valid. Our review confirms no negative values for time-based variables and correctly shows no sales where stores have been closed. Timeliness does not apply to this report, as we are dealing with historical sales and not providing Rossmann with commercial advice based on the analysis.

## 3.2 Variable Quality

Evaluating the variable quality informs decisions on transformations. Returning to "StoreType", this variable is not the only one with alphabetical categories— "Assortment" and "StateHoliday" also categorize using a, b, c (with "StateHoliday" also having a value of 0). These similarities may cause confusion when interpreting or presenting results. "CompetitionDistance", "CompetitionOpenSinceMonth", "CompetitionOpenSinceYear", "Promo2SinceWeek", and "Promo2SinceYear" all have missing values, complicating their use in analysis. "PromoInterval" includes categories of concatenated months where "Promo2" is active, presenting challenges for use as predictors in modeling.

## 3.3 Data Transformation and Imputation

Merging the train and store datasets is necessary to include all information about the stores, but before this, some variable transformations and imputations are realized. Before applying any imputation, the nature of the missingness of the data is evaluated. Figure 1 visualizes this missingness, with the percentage of missing data ranging from 0-40%, suggesting a localized approach to addressing missingness. The data is Missing At Random (MAR) for Promo2 time-based variables, as it relates to observed data. For competitor time-based variables, they might have been lost during data collection, which wouldn't be surprising given the years passed.

![Visualisation of the data’s missing patterns](https://github.com/user-attachments/assets/42aae322-b8a8-41d9-a474-facf88821053)

We address the three missing values in competition distance by imputing with the median, as non-zero values for CompetitionOpenSinceMonth/Year imply the competitors exist. Time-based variables for competition are imputed by mode for ordinal variables like these. For "Promo2" time-based variables, missing values exist only when "Promo2" is zero, meaning we can replace missing values with zero without affecting the model. Additionally, "test.csv" lacks 11 'Open' values—all from store 622. Assuming these are not closed days, we replace them with 1. 


## 3.4 Assessment of Redundant Observations or Outliers

In "test.csv", 41,088 observations over 48 days result in 856 unique stores out of 1,115. By deleting observations corresponding to stores not in the test set, we reduce the dataset by approximately 25%. Furthermore, deleting observations where stores are closed simplifies the prediction of sales and customers, as these are trivial cases. Figure 2's boxplots of sales and customers reveal a skewed distribution, partially addressed by removing the 99th percentile, a common practice in preprocessing to reduce skewness.

![Boxplots of sales (left) and customers (right)](https://github.com/user-attachments/assets/e8848012-255a-470e-946d-40b6f8ed9999)

## 3.5 Data Linkage & Feature Extraction

To localise all information, we merge “train.csv” with “stores.csv” by the unique identifier ‘Store’. This is the dataset we’ll be using for training the model later. Using “Date”, we extract features “DayNumber”, “Week”,“Month” and “Year” separately, this is so that we can utilise them in the model and analyse sea- sonal patterns in the data. We also transform both the two promo2 and two competition time-based variables into one each, which is done by converting these all in the same format. We now have two variables: “CompetitionTotalMonths” and “Promo2TotalMonths”; not only does this transformation reduce the load due to reduced variables but they are also easier to work with as they are completely numerical.

# 4 Exploratory Data Analysis

Figure 3 shows the correlation matrix for the numeric variables after all steps above. Avoiding multicolinearity in the model is a must - the extracted features are totally correlated with the features that they’re made from, we need to bear this in mind for feature selection. Despite this, we see that “DayofWeek”, “Promo”, ”Promo2”, “Promo2TotalMonths” and “Customers” are the variables most correlated with sales. For customers it’s similar, except “CompetitionDistance” with -0.12. This means that stores located farther away from competitors may attract more customers.

![Correlation matrix after pre-processing the data](https://github.com/user-attachments/assets/790aaabc-5a56-4df1-9626-f762db7ca7f4)

Let's look at the average customer and sales for each store type. We see that the lowest average sales and the highest average customers are from store type ‘b’ - implying that customers may make small purchases only that this type of store. Since we do not know the type, we could possibly assume that these types are smaller, convenience-type stores.

![AvgcAvgsStoreType](https://github.com/user-attachments/assets/044b3491-fa83-4cdd-8134-9ccd3b6d1c9c)

Plotting average sales each week by promotion (see the figure below), the light-blue line which represents the stores participating in a promotion have consistently better sales than the stores that do not participate in the promotion. However, for both classes, there is a spike seen around week 50-52, indicating a surge in sales around the Christmas holidays.

![AvgSalesPerWeekByPromotion](https://github.com/user-attachments/assets/25cbc54b-df18-4577-8b9f-cb0676648dbb)

# 5 The Model

XGBoost uses regularization which prevents overfitting and enhances model performance in real-world scenarios. Like random forest, it can handle large datasets, but it’s less computationally intensive than random forest; another reason why I have chosen it. Unlike linear models, it is also robust to outliers. After careful consideration and experimentation, the features chosen for the models are Store, DayOfWeek, Promo, StateHoliday, SchoolHoliday, Promo2, Promo2TotalMonths, CompetitionDistance, Assortment, StoreType, Week, Month, and Year. The next plot shows the predicted vs. actual values for both sales and customers. Respectively, the models had a Root Mean Squared Percentage Error (RMSPE) of 15.5% and 13.5%. A lot of errors are apparent from the high values.

![Plotted predictions against actuals for Sales and Customers](images/PredvActual.png)

# 6 Results, Limitations & Assumptions

Now we apply the models to “test.csv” - results from the figure below.

![Distributions of predicted sales and customers in the test dataset](images/FinalPlot.png)

One of the things I attempted first was to separate the train and test data of “train.csv” by the date, so that we’re predicting the future rather than random dates. This didn’t work and caused an infinite RMSPE, so I resorted to a random split. However, this leads to data leakage because the model is trained on future data. To combat this, cross-validation with time series would work, but this is computationally heavier. Unfortunately, the computational load for random forest and XGBoost was too much in R, where I conducted all of the pre-processing and exploratory analysis. I carried out the model in Python as I was continuously only able to run linear models with errors of around 40%.

