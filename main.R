################################################################################################
################################################################################################
# IMPORT
################################################################################################
################################################################################################

###########################################################
# Load packages
###########################################################
# Used throughout
library(dplyr)

# load the library
library(mlbench)
# identify best features
library(caret)
# create correlation plot
library(corrplot)

library(DAAG)
# Output to copy
library(xtable)
###########################################################
# Load CSVs
###########################################################
setwd("~/Library/Mobile Documents/com~apple~CloudDocs/Documents/School/Laurier (2017-2018)/Business Analytics/Final Project/hockey-ref-dataset")
basic <- read.csv('basic_stats.csv', stringsAsFactors = FALSE, strip.white = TRUE)
advanced <- read.csv('advanced_stats.csv', stringsAsFactors = FALSE, strip.white = TRUE)
sportrac <- read.csv('sportrac-all.csv', stringsAsFactors = FALSE, strip.white = TRUE)
salary_caps <- read.csv('salary_caps.csv', stringsAsFactors = FALSE, strip.white = TRUE)

# Due to limited availability of salary data, we are using a different source for the 
# test data. However, this should not affect anything.
test <- read.csv('2015_super_spreadsheet.csv', stringsAsFactors = FALSE, strip.white = TRUE)
################################################################################################
################################################################################################
# PREPARE
################################################################################################
################################################################################################
cleanName <- function(col) {
  # Strip player id
  cleaned <- gsub(pattern = "([A-Za-z]\\s*)\\\\[0-9a-zA-Z\\s]+", replacement = "\\1", x=col)
  cleaned <- gsub(pattern = ".", replacement = "", x=cleaned, fixed=TRUE)
  cleaned <- gsub(pattern = "-", replacement = " ", x=cleaned, fixed=TRUE)
  cleaned <- gsub(pattern = "'", replacement = "", x=cleaned, fixed=TRUE)
  cleaned <- gsub(pattern = " ", replacement = ".", x=cleaned, fixed=TRUE)
  return(toupper(cleaned))
}

allFWD <- function(dataframe) {
  return(subset(dataframe, dataframe$TXTPOSITION != 'D'))
}

allDEF <- function(dataframe) {
  return(subset(dataframe, dataframe$TXTPOSITION == 'D'))
}

basic$TXTPLAYERNAME <- cleanName(basic$Player)
advanced$TXTPLAYERNAME <- cleanName(advanced$Player)

###########################################################
# Remove non-totals for players who played on multiple teams
# If the player occurs multiple times, then select the "Total"
# row, otherwise keep the one row.
###########################################################
basic <- basic %>%
  group_by(Rk) %>%
  filter((n() > 1 & Tm == "TOT") | n() == 1)
#####


###########################################################
# Join the basic and advanced tables together
###########################################################
hockey_ref <- inner_join(basic, advanced, by="Rk", suffix=c("basc", "adv"))


###########################################################
# Clean the names
###########################################################

# Clean name to same format as Hockey Reference
sportrac$TXTPLAYERNAME <- cleanName(sportrac$TXTPLAYERNAME)
sportrac$NUMCONTRACTSTART <- as.numeric(gsub(".*\\((.*)\\-(.*)\\).*", "\\1", sportrac$Player))
# Use contract end instead of free agent as some free agent years are missing
sportrac$NUMCONTRACTEND <- as.numeric(gsub(".*\\((.*)\\-(.*)\\).*", "\\2", sportrac$Player))
# Strip the dollar sign formatting and cast to numeric
sportrac$NUMCONTRACTAVGVAL <- as.numeric(gsub("[\\$,\\s]*", "", sportrac$Average))
sportrac$NUMCONTRACTTOTALVAL <- as.numeric(gsub("[\\$,\\s]*", "", sportrac$Dollars))
sportrac$NUMCONTRACTLEN <- as.numeric(sportrac$Yrs)


###########################################################
# There are sometimes multiple names where a player occurs
# twice due to multiple contracts. Let's only take the 
# contracts expiring this year or later. For example,
# Josh Leivo has a 2015-2017 contract and a 2018-2018 contract.
# We are only taking the latter.
###########################################################
sportrac <- sportrac %>%
  group_by(TXTPLAYERNAME) %>%
  filter((n() > 1 & NUMCONTRACTEND >= 2018) | n() == 1)

# Join the salary cap table with the salaries
sportrac.1_caps <- inner_join(sportrac, salary_caps, by=c("NUMCONTRACTSTART" = "YEAR"))
# Calculate the average salary as a percentage of the salary cap in the year the contract signed
sportrac.1_caps$NUMCONTRACTPERC <- sportrac.1_caps$NUMCONTRACTAVGVAL / (sportrac.1_caps$UPPER * 1e6)

sportrac.2_clean <- subset(sportrac.1_caps, select=c(
  "TXTPLAYERNAME", "NUMCONTRACTSTART", 
  "NUMCONTRACTEND", "NUMCONTRACTLEN", 
  "NUMCONTRACTAVGVAL", "NUMCONTRACTTOTALVAL",
  "NUMCONTRACTPERC"
)
)
df.joined <- inner_join(hockey_ref, sportrac.2_clean, by=c("TXTPLAYERNAMEbasc" = "TXTPLAYERNAME"))
df.unmatched <- anti_join(hockey_ref, sportrac.2_clean, by=c("TXTPLAYERNAMEbasc" = "TXTPLAYERNAME"))

###########################################################
# Add Per 60 Statistics (60 minutes per game - standardized)
###########################################################
df.joined$NUMPER60.G  <- (df.joined$G  / df.joined$TOI) * 60
df.joined$NUMPER60.A  <- (df.joined$A  / df.joined$TOI) * 60
df.joined$NUMPER60.CF <- (df.joined$CF / df.joined$TOI) * 60
df.joined$NUMPER60.CA <- (df.joined$CA / df.joined$TOI) * 60
df.joined$NUMPER60.TO    <- (df.joined$TK - df.joined$GV) / df.joined$TOI * 60


#########################################################
# Remove Linearly Dependent Rows and Rename Some Merge Conflicts
# Rk => HockeyReference sort order
# PTS=  GOALS + ASSISTS
# G, A, CA, CF => Changed to per 60 stats
# S => Shots is nearly equivalent to Fenwick / CF
# SAtt. => Shots attempted
# ATOI => Average Time on Ice => TOI / G
# TK & GV => Changed to per 60 statistic (NUMNETTO)
# FO. => Face Off Percentage = (Face-offs won - faceoffs lost)/ (Faceoffs won + faceoffs lost)
#   - percentage is more valuable than individual won, loss, so dropping the individuals
# PDO = oiSV% + oiSH% (on ice shooting + on ice safe)
# X... => Renamed to NUMPLSMNS
########################################################
df <- df.joined[ , !names(df.joined) %in% c(
  "Rk", "G","A", "CA", "CF", "PTS", "S", "ATOI",
  "FOW", "FOL", "SAtt.", "Ageadv", "GPadv", 
  "Playerbasc", "Playeradv", "Ageadv", "TXTPLAYERNAMEadv", "Posadv", 
  "TK", "GV", "oiSH.", "oiSV.")]
df <- df %>%
  rename(NUMSHTPERC=S., NUMAGE=Agebasc, NUMGP=GPbasc, NUMPLSMNS=X...,
         FO.PERC=FO., TXTPLAYERNAME=TXTPLAYERNAMEbasc, TXTPOSITION=Posbasc)

# Create an ID Column - used for feature selection to identify players
df$ID <- seq.int(nrow(df))

# Move id to first column and player name to second column
df <- df %>% 
  select(ID, TXTPLAYERNAME, TXTPOSITION, everything())


# Impute NA - 0 for shooting percentage nil
df$NUMSHTPERC[is.na(df$NUMSHTPERC)] <- 0.0
# Impute NA = 0 for shots "Thru". to the net
df$Thru.[is.na(df$Thru.)] <- 0.0
# Impute NA - 0 for faceoff percentage nil
df$FO.PERC[is.na(df$FO.PERC)] <- 0.0

df$TXTPOSITION <- as.factor(df$TXTPOSITION)
df$TXTTEAM <- as.factor(df$Tmbasc)

# Calculate the age of the player from the year the contract was signed
df$NUMAGE.START <- df$NUMAGE - (2018 - df$NUMCONTRACTSTART)


# The following function takes a column as input and imputes the
# median .
impute_median <- function(x){
  ind_na <- is.na(x)
  x[ind_na] <- median(x[!ind_na])
  as.numeric(x)
}

# Impute median for oiSV.% and PDO
impute_median(df$oiSV.)
impute_median(df$PDO)

# Set games played qualifier to 10
df <- df %>%
  filter(NUMGP > 10)

########################################################

################################################################################################
################################################################################################
# ANALYSIS
################################################################################################
################################################################################################

###########################################################
# Feature selection
# For feature selection, we only want to predict based off
# of the hockey statistics as the contract information is
# unknown at the time. Thus, we create a new dataframe
# that just contains the salary and hockey info and use that
# to determine the most important attributes. (NUMERICAL ONLY)
###########################################################
feature_selection.fwd <- df %>%
  filter(TXTPOSITION != "D") %>%
  select_if(is.numeric) %>%
  select(-matches('CONTRACTA|CONTRACTS|CONTRACTE|CONTRACTL|CONTRACTT'))
# UGLY WORKAROUND TO EXCLUDE ALL CONTRACT RELATED VALUES
feature_selection.def <- df %>%
  filter(TXTPOSITION == "D") %>%
  select_if(is.numeric) %>%
  select(-matches('CONTRACTA|CONTRACTS|CONTRACTE|CONTRACTL|CONTRACTT'))

# calculate correlation matrix
correlation.fwd <- cor(feature_selection.fwd,  use = "complete.obs")
correlation.def <- cor(feature_selection.def,  use = "complete.obs")

corrplot(correlation.fwd, order='hclust', tl.cex = 0.5)

# find attributes that are highly corrected (ideally >0.75)
highly_correlated.fwd <- findCorrelation(correlation.fwd, cutoff=0.5, verbose = TRUE)
highly_correlated.def <- findCorrelation(correlation.def, cutoff=0.5, verbose = TRUE)

# prepare training scheme
control <- trainControl(method="repeatedcv", number=10, repeats=3)

model.all_vars.fwd <- train(NUMCONTRACTPERC~., feature_selection.fwd, method="lm", preProcess="scale", trControl=control, na.action = na.pass)
model.all_vars.def <- train(NUMCONTRACTPERC~., feature_selection.def, method="lm", preProcess="scale", trControl=control, na.action = na.pass)

# estimate variable importance
importance.fwd <- varImp(model.all_vars.fwd, scale=FALSE)
importance.def <- varImp(model.all_vars.def, scale=FALSE)

# summarize importance
print(importance.fwd)
print(importance.def)
# plot importance
plot(importance.fwd, main="Importance of Variables - FWD")
plot(importance.def, main="Importance of Variables - DEF")

######################################################################################
# Clean test data
######################################################################################

# Eliminate all the blank rows at the bottom
test <- test[!(is.na(test$Last.Name) | test$Last.Name==""), ]
# test data is from 2015 => 2015 - 1900 = 115
test$NUMAGE <- 115 - as.numeric(substr(test$DOB, nchar(test$DOB)-2+1, nchar(test$DOB)))
test$TXTPLAYERNAME <- cleanName(paste(test$First.Name, test$Last.Name))
test$FO.PERC <- as.numeric(sub("%", "", test$FO.)) / 100.000000000
test <- test %>%
  rename(NUMGP=GP, HIT=HitF, BLK=BkS, TXTPOSITION=Pos)

test$NUMPER60.G  <- (test$G  / test$TOI) * 60
test$NUMPER60.A  <- (test$A  / test$TOI) * 60
test$NUMPER60.CF <- (test$CF / test$TOI) * 60
test$NUMPER60.CA <- (test$CA / test$TOI) * 60
test$NUMPER60.TO    <- (test$TK - test$GV) / test$TOI

test$NUMCONTRACTPERC <- (test$Cap.Cost + test$CHIP) / 71.4

test <- test %>%
  filter(NUMGP > 10)
#test$CorsiFor

###########################################################
# Create Models
###########################################################


model.fwd <- lm(NUMCONTRACTPERC ~ NUMAGE + NUMGP  + TOI + FF, data = allFWD(df))
summary(model.fwd)
model.def <- lm(NUMCONTRACTPERC ~ NUMAGE + NUMGP + PIM + HIT + A.PP + FF + NUMPER60.CA, data = allDEF(df))
summary(model.def)

coefficients(model.fwd)
coefficients(model.def)


layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(model.def)

layout(matrix(c(1),1,1)) # optional 4 graphs/page 

#cv.lm(df=test, model.fwd, m=3) # 3 fold cross-validation
#confint(model.fwd)
# Do they appear to be a bell curve? = Normally distrobuted
#hist(residuals(model.fwd))

pred.fwd <- predict(model.fwd, newdata = allFWD(test))
pred.def <- predict(model.def, newdata = allDEF(test))

summary(pred.fwd)
summary(pred.def)

test.pred_fwd <- cbind(allFWD(test), NUMCONTRACTPREDICT = pred.fwd)
test.pred_def <- cbind(allDEF(test), NUMCONTRACTPREDICT = pred.def)
test.pred <- rbind(test.pred_fwd, test.pred_def)

test.pred$NUMEXCESSVALUE <- test.pred$NUMCONTRACTPREDICT - test.pred$NUMCONTRACTPERC

######################################################################################
# Output
######################################################################################

output.top_10_fwd <- test.pred %>%
  filter(TXTPOSITION != 'D') %>%
  select(TXTPLAYERNAME, End.Team, TXTPOSITION, NUMCONTRACTPREDICT, NUMCONTRACTPERC) %>%
  top_n(n = 10, wt = NUMCONTRACTPREDICT)

output.top_10_def <- test.pred %>%
  filter(TXTPOSITION == 'D') %>%
  select(TXTPLAYERNAME, End.Team, TXTPOSITION, NUMCONTRACTPREDICT, NUMCONTRACTPERC) %>%
  top_n(n = 10, wt = NUMCONTRACTPREDICT)

output.player_excess_value_negative <- test.pred %>%
  select(TXTPLAYERNAME, End.Team, TXTPOSITION, NUMCONTRACTPREDICT, NUMCONTRACTPERC, NUMEXCESSVALUE) %>%
  top_n(n = -10, wt = NUMEXCESSVALUE)

output.player_excess_value_zero <- test.pred %>%
  select(TXTPLAYERNAME, End.Team, TXTPOSITION, NUMCONTRACTPREDICT, NUMCONTRACTPERC, NUMEXCESSVALUE) %>%
  filter(NUMEXCESSVALUE <= 0.00001 & NUMEXCESSVALUE >= -0.99999) %>%
  arrange(desc(NUMEXCESSVALUE)) %>%
  slice(1:10)

output.player_excess_value_positive <- test.pred %>%
  select(TXTPLAYERNAME, End.Team, TXTPOSITION, NUMCONTRACTPREDICT, NUMCONTRACTPERC, NUMEXCESSVALUE) %>%
  top_n(n = +10, wt = NUMEXCESSVALUE)


output.team_excess_value <- test.pred %>%
  group_by(End.Team) %>%
  summarise(ev = weighted.mean(w = NUMCONTRACTPERC, x = NUMEXCESSVALUE)) %>%
  arrange(desc(ev))

#  summarise(count = count(TXTPLAYERNAME))

copytable <- function(x, ...) {
  f <- tempfile(fileext=".html")
  print(xtable(x, ...), "html", file = f)
  browseURL(f)
}

copytable(output.top_10_fwd, digits = 4)
copytable(output.player_excess_value_zero, digits = 4)
copytable(output.player_excess_value_positive, digits = 4)
copytable(output.player_excess_value_negative, digits = 4)


barplot(output.team_excess_value$ev, names.arg = output.team_excess_value$End.Team, las=2, xlab="Team", ylab="Excess Value")


plot(importance.fwd)


plot(importance.def)


