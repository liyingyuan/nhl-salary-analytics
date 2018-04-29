# NHL Salary Analytics

*Note: The following report was written for a final project with the target audience of a business decision maker.*

## Introduction

**Motivation**

An NHL skater’s (i.e. not goalie) value is a sum of three main components: his on-icecontributions, his off-ice intangibles, and his contract. Most teams use scouts and analytics of welldefined statistics to track the players’ contributions on-ice, such as goals, assists and Corsi. Off-iceintangibles (e.g. grit, leadership, mentorship) are difficult to quantify, subjective, and vary in importancefrom team to team. NHL player salaries are well defined unlike the off-ice intangibles but there is nodefined procedure to evaluate how fair a salary is. This is made complicated by the fact that players arepaid for their future value, not just their current value. Therefore, to predict salaries, it is first important todetermine what factors result in players earning higher salaries? Second, what influences teams tooverpay certain players while ignoring players whose value exceeds their salary? Lastly, do certain teamsplayer evaluation techniques differ from the norm of the league?

**The Problem**

The existing process of offering contracts is flawed; teams generally identify comparable players(by play style, tenure, and statistics) and offer contracts similar to those players. However, this creates acircular dependency issue where the teams are relying on each other to determine the fair value of players.

Poor player evaluation techniques could carry forward through multiple players’ contracts. Using basicand hockey advanced statistics, is it possible to generate a multi-criteria model that will allow teams toindependently predict what a player’s salary should be?

### Use Cases

#### PLAYER'S USE CASE

A player would use this model during contract negotiations. During this period, the team and theplayer (and his agents) negotiate the player's salary. A player could use this model to determine his fairvalue prior to entering the negotiations. Then, throughout the negotiations, the player would have abenchmark value to compare against the teams' offer(s). A player can also use the model to know whichstatistics are most related to a higher salary and focus his play on increasing those statistics.

#### TEAM'S USE CASE

The team's assistant general managers and analytic departments ("team") will be the main users ofthis model. These managers will be the opposing party of the player during contract negotiations with freeagents or resigning players on the team's roster. The team's management will use the model to develop atarget salary to pay the player (e.g. 75% of the predicted salary), a "walk-away" salary (e.g. 125% of thepredicted salary) and will aim to pay the player somewhere in the range.

The model will also allow the team to identify other teams whose player evaluation techniquesdiffer from the norm. If a team repeatedly underpays players who are producing surplus value, then thiscould indicate team has excellent player evaluation techniques and reveal clues about traits that the teamvalues. In contrast, if a team repeatedly overpays players who are under producing, then that team couldbe a potential trade target due to their poor player evaluation techniques.

More importantly, the team could use the model to identify players whose value exceeds theirprice. This will allow the team to take advantage of market inefficiencies when trading for players,signing free agents or monitoring their own team.

## The Data Training Data

**Training Data**

The training data is from three sources: HockeyReference, Sportrac and a manually aggregatedspreadsheet of the league salary cap from 2008 to present. The HockeyReference and Sportrac data weredownloaded from their respective websites.

Hockey Reference splits the required data into two tables: Basic and Advanced. The Basic tablepresents demographical information on the player (i.e. name, date of birth, age, team, position) along withthe high level statistics (e.g. goals, assists, face-offs, penalties, ice time). The Advanced table showsadvanced statistics (i.e. Corsi, Fenwick, Zone Starts) for each player.

The Sportrac data provides the player name, team and contract details: length, total dollar value,average annual value and the years remaining. Note: the total dollar value of the contract represents thebase salary. Performance, practice and other off-ice incentives are not included in this figure.

The manually created spreadsheet of the league salary caps was compiled from various newsarticles pertaining to the league updating the salary cap and recording the salary floor, mid-point andsalary cap for each year. This spreadsheet was used to calculate the player's salary's percentage of thesalary cap of the year the contract was signed.

The data covers only the 2 017 - 2018 season due to duplication concerns and the limitedhistorical salary information available. Firstly, including multiple years of data would result induplication, as a player would be included in the dataset multiple times (i.e. once per year). One solutionto this would be to amalgamate multiple years into one row. However, this introduces the problem ofassigning multiple years of statistics to one salary. Secondly, there is limited historical salary informationavailable. Most resources are replaced yearly to provide current salary information.

**Testing Data**

Since salary data for previous years was not readily available, a different data source was requiredfor the testing data set. Rob Vollman's "Super Spreadsheet" for 2014 - 2015 covers basic and advancedstatistics from a variety of websites including HockeyReference and contractual information (i.e. thepercentage of the salary cap a player's salary possesses) (Vollman, 2015).

**Data Cleansing**

Despite originating from the same source, there were data structure differences betweenHockeyReference's Basic and Advanced tables. In the Basic table, a player who was changed teams midseason (i.e. was traded or released and signed) was presented in multiple rows for each team on whichthey played on, plus a "total" row that summed the statistics across all teams. To standardize the structure,all non-totals rows for skaters who played on multiple teams were filtered out.

In the Advanced table, there was missing data in several columns. For the columns Shooting %,Shots Through, and Face-off % where the missing data represented "no activity", the value zero wasassigned. For example, all defencemen had no activity on face-offs. For the columns On Ice Save % andPDO, the median value was assigned to the players missing data in these columns. Although the value ofthe missing column may not be reflective of the individual’s value, this was done to minimize the impactthe missing data would have on the entire dataset.

Another discrepancy occurred between HockeyReference and Sportrac - the formatting andabbreviation of NHL players' names varied (i.e. “Matt” vs. “Matthew”). Additionally, names with specialcharacters (i.e. dash, period or apostrophe) and the spelling of Russian names varied betweenHockeyReference and Sportrac. To resolve this issue, all names were subjected to the same namecleansing routine that normalized the names across the different sources. The individual cases where thename was abbreviated were resolved by hand.

The Sportrac data was cleansed to remove the text from numeric fields (i.e. removing the text"yr" after every contract term length) allowing the fields to be interpreted as numbers. Lastly, the Basic,Advanced and Sportrac tables were combined into one table. A minimum requirement of 10 games playedwas required to filter out players who did not have a large enough sample size.

### Data Validation

The HockeyReference data is highly reputable and trusted within the industry. Random samplingwas done by comparing the statistics of one player, every 50 rows and comparing that data to NHL.com(i.e. 14 players in total). There were no material differences, only small differences occurred in time onice that were negligible. However, the Sportrac data is not as reliable, despite being the "largest onlinesports team & player contract resource on the web" (Ginniti, 2007). This is an unmitigated risk due to thefact that contract details are not always disclosed to the public. When manually cross-referencingcontracts with other sites that publish contracts, there were a number of contracts that differed. Onepossible reason is some sites may calculate a player's salary as a function of which level he played in (i.e. when playing in the AHL, the player earns the AHL salary; when playing in the NHL, the player earns theNHL salary). Another possible reason is players in the NHL level are deducted salary for games misseddue to suspension or unsportsmanlike conduct fines accrued during games.

### Redundant Explanatory Variables

A final issue with the data was the fact that there were numerous redundant explanatory variables.

To simplify and generalize the model, it was important to first reduce the number of explanatory variablesas much as possible. Any column that could be represented by a combination of two or more columns waseliminated. For example, the Points column was removed as it is the sum of goals and assists. Duplicateswere removed by summarizing multiple columns into one column when the detail was not required (e.g. face-off wins and face-off losses were summarized into face-off win percentage).

## Analysis

Multiple Linear Regression (MLR) models the relationship between two or more explanatoryvariables (i.e. independent variables) and a response variable (i.e. dependent variable) (Lacey, 1998). Theoutput of the model will be two items: the relative importance of each explanatory variable (i.e. a weight) and a mathematical formula combining the weights and the values to predict the response variable.

### Why Multiple Linear Regression?

First, each of the explanatory variables is linearly related to the response variable (Lund ResearchLtd., 2013). Essentially, this indicates that if the explanatory and response variable were plotted on agraph, the relationship could be connected with a straight line (i.e. no curves).

Second, MLR is only suitable when response variable (salary) is a continuous number – numbersare not fixed at certain intervals and are neither binary (i.e. response variable is not either 0 or 1) norcategorical (i.e. there are not a fixed number of outcomes).

Last, the simplicity of MLR was a key criterion of selecting a type of prediction. If the model isnot easily understood, management may resist adoption. Additionally, a model should be updatable whennew information is made available. A more complex model would be very difficult to update if it requiredretraining whenever new data is received. However, with a MLR model, a user of the model can applynew data to the model with a calculator or Microsoft Excel.

### The Approach

The first step after data cleansing is to identify the response variable. Simply taking the salary in the current year is not sufficient. Suppose player A and player B signed equal dollar value contracts in consecutive years. The percentage of the salary cap that each player's contract occupies would be different due to increases in both the salary cap and inflation. Additionally, the salary in the current year may be front or back-loaded resulting in an inaccurate representation of the current year's salary. Tomitigate this issue, the response variable is the annual average value of the contract (i.e. total dollar valuedivided by the # of years) as a percentage of the salary cap of the year the contract was signed. Forexample, Alex Ovechkin's contract was signed in 2009 for $124M over 13 years. The salary cap in 2009was $56.7M. Thus, the model would calculate Ovechkin's salary as 17% of the salary cap (i.e. $124M÷13yrs ÷ 56.7M _x_ 100%) (CapFriendly).

Thus, the response variable will be an estimate of average annual value for the player's services.

However, the NHL’s Collective Bargaining Agreement has many restrictions on contract length anddollar value. These limitations are not reflected in the model, which may result in negative salaries(violating the minimum salary clause) or areas where players salaries are much lower than predicted dueto contract maximums for younger players, yet to reach unrestricted free agency status.

### EXPLANATORY VARIABLES

It is first important to consider that the priorities of forwards and defencemen differ. Thus, twodifferent models will be generated: one for forwards and one for defencemen. The specific variables were selected by the t-statistic, which describes how extreme a variable is (i.e. is the explanatory variable’s impact on the response variable due to random chance or the actual variable) (Simon). A t-statistic further away (positive or negative) from zero is "better". The t-statistic is advantageous because it is in the units of the response variable (Runkel, 2016). Thus, it is possible to quantify how important a variable is to predicting salaries. Refer to Appendix A for a plot of the importance of each variable. Similarly to the initial data cleansing, some manual tweaking was done tostreamline the model and improve the accuracy. For instance, including the age of the player when he signed his contract and the age of the player at the present day were repetitive and the former did notmaterially impact the model if the current age was already included in the model.

The models were trained with the 2017 - 2018 data resulting in the two linear equations below.

The output of these equations is the response variable --- the percentage of the salary cap that theplayer is estimated to occupy. To obtain the player's estimated salary, multiply the value obtained fromthe equation by the salary cap of the year to be predicted.

The weights associated with each explanatory variable are intuitive: as the player ages, generatesmore powerplay assists, shots increase, the predicted salary increases, while as the hits given increases,the salary decreases, reflecting the game today favouring speed over physicality. However, as the numberof games played increases, the predicted salary decreases. Although this may seem illogical at first, if allother variables are held constant and the number of games played increases, then the other statisticsdecrease on a per game basis making the player less valuable.

These equations will then be applied to the testing dataset from the 2015 - 2016 season. For eachplayer, the Excess Value is the difference between the predicted value and the actual value from thetesting dataset. This value will indicate which players are overvalued (i.e. EV < 0), which players areundervalued (i.e. EV > 0) and which players are paid at fair value (i.e. EV = 0). Additionally, the ExcessValue can also be used to summarize a team's roster. This allows teams to be compared by the averageExcess Value of their roster.

## Results

Now that the model is defined, it is possible to determine if this model is a good predictor of aplayer's salary. This will be determined by (adjusted) R^2 , which is the percentage of the salary variationthat is explained by the model, adjusted for the number of predictors in the model (four for forwards, fivefor defencemen). In other words, the R^2 shows how close the actual data point is from the prediction line![eqs](https://latex.codecogs.com/gif.latex?%5Cinline%20FWD%20%3D%20%5Cfrac%7B1%7D%7B1000%7D%20%282.94%5Ctextup%7BAGE%7D%20-%201.94%5Ctextup%7BGP%7D%20+%200.09%5Ctextup%7BTOI%7D%20+%200.08%5Ctextup%7BFenFor%7D%20-%2041.87%29%5C%5C%20DEF%20%3D%20%5Cfrac%7B1%7D%7B1000%7D%20%282.96%5Ctextup%7BAGE%7D%20-%201.01%5Ctextup%7BGP%7D%20+%200.20%5Ctextup%7BPIM%7D%20-%200.03%5Ctextup%7BHIT%7D%20+%201.35%5Ctextup%7BPPAst%7D%20-%2015.95%29)(after plotting the equation on a graph). In general, the higher the R^2 , the better the data fits the model(where the highest possible is 100%) (Frost, 2013).

In Appendix B, a plot of the predicted vs. actual salaries, it can be observed that the fit is quitestrong for both forwards and defencemen as the line stays in the middle of all data points. The forwardsmodel has an R^2 of 0.6029, meaning the four variables were able to explain 60.29% of the variation whilethe defencemen model has an R^2 of 0.5919, meaning the five variables explain 59.19% of the variation.

In Appendix C, a plot of average excess value by teams weighted by actual salary (i.e. negativeexcess value is more harmful to the team when the contract is larger), it is evident that San Jose, a StanleyCup finalist, has extracted significantly more excess value than any other teams. The reasons for thediscrepancy are unknown but present an excellent follow-up opportunity for the other 29 teams.

Appendix D lists the top ten forwards and defencemen by predicted salary. The results are asexpected, with the marquee players occupying both lists.

In Appendix E, the tables demonstrate which players were the most overpaid, underpaid andfairly paid in the 2015-2016 season. Nine of the top ten overpaid players were forwards. Of the top tenmost underpaid players, eight were over the age of 30, likely due to the players taking a discount for agreater opportunity at winning the Stanley Cup.

## Recommendation

Overall, it is recommended that every NHL and its minor league associates implement NHLsalary prediction models. Predicting salary through analytics can be combined with the traditionalcomparison approach to result in the best value for the team.

While both models have room for improvement, the models are fairly accurate considering thefew number of inputs, the lack of subjective inputs (i.e. 3-stars, all-star nominations, team preferences)and the lack of adjustments made for the league minimum or collective bargaining act provisions. If ateam were to adopt the models, they could be evolved into team specific models that value certain traitsthe team emphasizes in its game style and coaching with the added benefit of more accuracy as the teamshave access to proprietary information.

![exhibit-1](exhibits/exhibit-1.png)

![exhibit-2](exhibits/exhibit-2.png)

![exhibit-2](exhibits/exhibit-3.png)

![exhibit-2](exhibits/exhibit-4.png)

## Bibliography

1. CapFriendly. (n.d.). https://www.capfriendly.com/players/alex _Alex Ovechkin_. From CapFriendly: -ovechkin

2. Frost, J. (2013, May 30). _Goodness-of-Fit?_ From The Minitab Blog: [http://blog.minitab.com/blog/adventures](http://blog.minitab.com/blog/adventures) _Regression Analysis: How Do I Interpret R-squared and Assess the-r2-in-statistics2/regression-analysis-how-do-i-interpret-r-squared-and-assess-the-goodness-of-fit

(^) 3. Ginniti, M. (2007). _About_. From Sportrac: [http://www.spotrac.com/about/](http://www.spotrac.com/about/)

4. Lacey, M. (1998). [http://www.stat.yale.edu/Courses/1997](http://www.stat.yale.edu/Courses/1997) _Multiple Linear Regression_ - 98/101/linmult.htm. From Yale Statistics:

5. Lund Research Ltd. (2013). Laerd _Multiple Linear Regression Analysis using SPSS Statistics_. FromStatistics: https://statistics.laerd.com/spss-tutorials/multiple-regression-using-spss-statistics.php(^) 

6. Runkel, P. (2016, November 4). _What Are T Values and P Values in Statistics?_ From TheMinitab Blog: [http://blog.minitab.com/blog/statisticsand-p-values-in-statistics](http://blog.minitab.com/blog/statisticsand-p-values-in-statistics) - and-quality-data-analysis/what-are-t-values

7. Simon, S. (n.d.). [http://www.pmean.com/definitions/tstat.htm](http://www.pmean.com/definitions/tstat.htm) _What is a tstatistic?_ (C. M. Hospital, Producer) From

8. Vollman, R. (2015, May 30). [http://www.hockeyabstract.com/testimonials/nhl2014](http://www.hockeyabstract.com/testimonials/nhl2014) _NHL 2014-15 Player Data_ - 15playerdata. Retrieved 2015 from HockeyAbstract:
