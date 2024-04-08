# 1 Introduction

Sales forecasting is necessary for commercial businesses to make future decisions based on demand. In this report, the data collected are from Rossmann, a pharmaceutical store chain in Europe over the course of two and a half years. It consists of 1,115 franchises located across Germany. The main objective is to preprocess the data in such a way that it is reliable enough to conduct an exploratory analysis. This involves multiple steps, which include assessing the data quality, data cleaning, data transformation, and finally, reducing the data. This is preceded by choosing and constructing a model that predicts 6 weeks of daily sales, of which the accuracy is appropriately evaluated.

# 2 Description of the Data

The data are separated into three datasets, called “store.csv”, “train.csv”, and “test.csv”. Tables 1 and 2 in Appendix A present the variables within the store dataset and the train/test dataset, respectively, as well as their description. To summarize, “store.csv” contains the information for each Rossmann franchise, and thus has 1,115 observations; “train.csv” and “test.csv” both contain the sales data each day from 01/01/2013 to 31/07/2015, except for “test.csv” that Sales and Customers are unknown for the period of 01/08/2015 to 17/09/2015. These variables will be referenced throughout the report.

# 3 Data Preprocessing

The importance of preprocessed data becomes apparent when attempting to train a model. Training on "dirty" data usually results in improper and inaccurate results. This report adopts a systematic approach to handling the Rossmann data.

## 3.1 Data Quality

We assess the data quality based on the dimensions defined by the Government Data Quality Hub [[1]](#references). The Rossmann data represents a real-world scenario of 1,115 stores, with their respective customers and sales, so we assess the accuracy of the information based on these given circumstances.

In terms of completeness, some variables' explanations appear vague; for example, "StoreType" has levels a, b, c, d, which signify the store models, but the descriptions of these models are not defined. This lack of information could be crucial in analysis—if a store model performs better monetarily, it could be due to factors other than the model itself. Regarding uniqueness, there are no duplicates in all three datasets, facilitating their combination. Consistency requires data values not to contradict each other, and all values or levels must be valid. Our review confirms no negative values for time-based variables and correctly shows no sales where stores have been closed. Timeliness does not apply to this report, as we are dealing with historical sales and not providing Rossmann with commercial advice based on the analysis.

## 3.2 Variable Quality

Evaluating the variable quality informs decisions on transformations. Returning to "StoreType", this variable is not the only one with alphabetical categories— "Assortment" and "StateHoliday" also categorize using a, b, c (with "StateHoliday" also having a value of 0). These similarities may cause confusion when interpreting or presenting results. "CompetitionDistance", "CompetitionOpenSinceMonth", "CompetitionOpenSinceYear", "Promo2SinceWeek", and "Promo2SinceYear" all have missing values, complicating their use in analysis. "PromoInterval" includes categories of concatenated months where "Promo2" is active, presenting challenges for use as predictors in modeling.

## 3.3 Data Transformation and Imputation

Merging the train and store datasets is necessary to include all information about the stores, but before this, some variable transformations and imputations are realized. Before applying any imputation, the nature of the missingness of the data is evaluated. Figure 1 visualizes this missingness, with the percentage of missing data ranging from 0-40%, suggesting a localized approach to addressing missingness. The data is Missing At Random (MAR) for Promo2 time-based variables, as it relates to observed data. For competitor time-based variables, they might have been lost during data collection, which wouldn't be surprising given the years passed.

We address the three missing values in competition distance by imputing with the median, as non-zero values for CompetitionOpenSinceMonth/Year imply the competitors exist. Time-based variables for competition are imputed by mode for ordinal variables like these. For "Promo2" time-based variables, missing values exist only when "Promo2" is zero, meaning we can replace missing values with zero without affecting the model. Additionally, "test.csv" lacks 11 'Open' values—all from store 622. Assuming these are not closed days, we replace them with 1.

## 3.4 Assessment of Redundant Observations or Outliers

In "test.csv", 41,088 observations over 48 days result in 856 unique stores out of 1,115. By deleting observations corresponding to stores not in the test set, we reduce the dataset by approximately 25%. Furthermore, deleting observations where stores are closed simplifies the prediction of sales and customers, as these are trivial cases. Figure 2's boxplots of sales and customers reveal a skewed distribution, partially addressed by removing the 99th percentile, a common practice in preprocessing to reduce skewness.

