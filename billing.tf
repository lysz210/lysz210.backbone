resource "aws_budgets_budget" "monthly_limit" {
  name              = "global-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "5"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"
  # ALERT 1: Spesa Reale raggiunge l'80% (4$)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["lysz210@gmail.com"]
  }
  # ALERT 2: Previsione (Forecast) di superamento del 100% (5$)
  # AWS calcola la proiezione basata sui consumi dei giorni precedenti
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["lysz210@gmail.com"]
  }
}