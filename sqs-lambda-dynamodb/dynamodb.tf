resource "aws_dynamodb_table" "sbl_service_acccount_request" {
  name         = "sbl_service_account_request"
  hash_key     = "request_id"
  range_key    = "tenant_id"
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "tenant_id"
    type = "S"
  }

  tags = {
    Environment   = "production"
    Team          = "sbl"
    Functionality = "SblServiceAccountRequestTable"
  }
}

resource "aws_dynamodb_table" "sbl_service_request_queue" {
  name         = "sbl_service_request_queue"
  hash_key     = "tenant_id"
  range_key    = "service_name"
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "tenant_id"
    type = "S"
  }

  attribute {
    name = "service_name"
    type = "S"
  }

  tags = {
    Environment   = "production"
    Team          = "sbl"
    Functionality = "SblServiceRequestQueue"
  }
}
