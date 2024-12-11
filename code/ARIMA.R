library(forecast)
library(randomForest)
library(Metrics)
library(data.table)

# 检查命令行参数
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: Rscript arima_ranger.R <data_path>")
}

data_path <- args[1]

# 动态生成输出文件名
base_name <- tools::file_path_sans_ext(basename(data_path))
metrics_file <- paste0(base_name, "_metrics.csv")
fitted_file <- paste0(base_name, "_fitted.csv")
forecast_file <- paste0(base_name, "_forecasted.csv")

# 读取数据
data <- fread(data_path)

# 数据准备：排除非数值型和时间列
data <- data[, !(names(data) %in% c("State", "Unnamed: 0", "Date_Time", "Latitude", "Longitude", "Elevation")), with = FALSE]
data <- data[, lapply(.SD, function(x) as.numeric(as.character(x)))]  # 转为数值型
data <- na.omit(data)  # 删除包含缺失值的行

# 数据划分为 7:3 的训练集和测试集
set.seed(123)
split_index <- floor(0.7 * nrow(data))
train_data <- data[1:split_index]
test_data <- data[(split_index + 1):nrow(data)]

# 初始化结果存储
fitted_values <- train_data[, .(Date_Time = seq_len(nrow(train_data)))]
forecasted_values <- test_data[, .(Date_Time = seq_len(nrow(test_data)))]
evaluation_metrics <- list()

# 排除降水量列 (目标变量)
exclude_var <- "Precipitation"
vars <- setdiff(names(data), exclude_var)

# ARIMA 模型部分（处理所有变量除降水量）
for (var in vars) {
  model <- auto.arima(train_data[[var]])
  train_pred <- fitted(model)
  test_pred <- forecast(model, h = nrow(test_data))$mean
  
  # 存储拟合值和预测值
  fitted_values[[paste0(var, "_fitted")]] <- train_pred
  forecasted_values[[paste0(var, "_forecast")]] <- test_pred
  
  # 计算指标
  train_actual <- train_data[[var]]
  test_actual <- test_data[[var]]
  
  mse_train <- mse(train_actual, train_pred)
  mae_train <- mae(train_actual, train_pred)
  r2_train <- 1 - sum((train_pred - train_actual)^2) / sum((train_actual - mean(train_actual))^2)
  
  mse_test <- mse(test_actual, test_pred)
  mae_test <- mae(test_actual, test_pred)
  r2_test <- 1 - sum((test_pred - test_actual)^2) / sum((test_actual - mean(test_actual))^2)
  
  evaluation_metrics <- append(evaluation_metrics, list(
    data.table(Variable = var, Dataset = "Train", MSE = mse_train, MAE = mae_train, R2 = r2_train),
    data.table(Variable = var, Dataset = "Test", MSE = mse_test, MAE = mae_test, R2 = r2_test)
  ))
}

# 随机森林部分（对降水量建模）
exclude_time <- setdiff(names(data), "Precipitation")
rf_model <- randomForest(Precipitation ~ ., data = train_data[, c("Precipitation", exclude_time), with = FALSE], ntree = 100)

# 使用训练集和测试集预测
rf_pred_train <- predict(rf_model, train_data[, exclude_time, with = FALSE])
rf_pred_test <- predict(rf_model, test_data[, exclude_time, with = FALSE])

# 存储降水量拟合值和预测值
fitted_values[["Precipitation_fitted"]] <- rf_pred_train
forecasted_values[["Precipitation_forecast"]] <- rf_pred_test

# 计算降水量的评价指标
train_actual <- train_data$Precipitation
test_actual <- test_data$Precipitation

mse_train <- mse(train_actual, rf_pred_train)
mae_train <- mae(train_actual, rf_pred_train)
r2_train <- 1 - sum((rf_pred_train - train_actual)^2) / sum((train_actual - mean(train_actual))^2)

mse_test <- mse(test_actual, rf_pred_test)
mae_test <- mae(test_actual, rf_pred_test)
r2_test <- 1 - sum((rf_pred_test - test_actual)^2) / sum((test_actual - mean(test_actual))^2)

evaluation_metrics <- append(evaluation_metrics, list(
  data.table(Variable = "Precipitation", Dataset = "Train", MSE = mse_train, MAE = mae_train, R2 = r2_train),
  data.table(Variable = "Precipitation", Dataset = "Test", MSE = mse_test, MAE = mae_test, R2 = r2_test)
))

# 保存结果
fwrite(rbindlist(evaluation_metrics), metrics_file)
fwrite(fitted_values, fitted_file)
fwrite(forecasted_values, forecast_file)

message("All calculations have been completed!")
