resource "aws_dynamodb_table" "my_dynamodb_table" {
  name         = "my-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
