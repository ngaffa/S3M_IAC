resource "aws_api_gateway_authorizer" "s3m-ag-authorizer" {
  name                   = "s3m-ag-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.s3m-ag-proxy.id
  authorizer_uri         = aws_lambda_function.s3m-lambda-authorizer.invoke_arn
  # authorizer_credentials = aws_iam_role.s3m-authorizer-invocation-role.arn

}
resource "aws_iam_role" "s3m-authorizer-invocation-role" {
  name = "s3m-authorizer-invocation-role"
  path = "/"
  assume_role_policy = file("policies/authorizer-policy.json")
}

resource "aws_iam_role_policy" "s3m-authorizer-invocation-policy" {
  name = "s3m-authorizer-invocation-policy"
  role = aws_iam_role.s3m-authorizer-invocation-role.id

  policy = replace(file("policies/invocation-policy.json"),"__LAMBDA_ARN__",aws_lambda_function.s3m-lambda-authorizer.arn)
}

resource "aws_iam_role" "s3m-lambda-role" {
  name = "demo-lambda"

  assume_role_policy = file("policies/lambda-policy.json")
  }


resource "aws_lambda_function" "s3m-lambda-authorizer" {
  filename      = "lambda-code/s3m-lambda-authorizer.zip"
  function_name = "s3m-lambda-authorizer"
  role          = aws_iam_role.s3m-lambda-role.arn
  handler       = "exports.handler"
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda-code/s3m-lambda-authorizer.zip")
  #"${base64sha256(filebase64("lambda-code/s3m-lambda-authorizer.zip"))}"
  #sha256(filebase64("lambda-code/s3m-lambda-authorizer.zip"))
  # filebase64sha256("lambda-code/s3m-lambda-authorizer.zip")
}