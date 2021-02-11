resource "aws_api_gateway_authorizer" "s3m-ag-authorizer" {
  name                   = "s3m-ag-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.s3m-ag-proxy.id
  authorizer_uri         = aws_lambda_function.s3m-lambda-authorizer.invoke_arn
}


resource "aws_iam_role" "s3m-lambda-role" {
  name = "s3m-lambda-role"

  assume_role_policy = file("policies/lambda-policy.json")
  }
  
  

resource "aws_lambda_permission" "lambda-permission-apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.s3m-lambda-authorizer.function_name
   principal     = "apigateway.amazonaws.com"
   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn =join("",[aws_api_gateway_rest_api.s3m-ag-proxy.execution_arn,"/*/*"]) 
}  


resource "aws_lambda_function" "s3m-lambda-authorizer" {
  filename      = "lambda-code/s3m-lambda-authorizer.zip"
  function_name = "s3m-lambda-authorizer"
  role          = aws_iam_role.s3m-lambda-role.arn
  handler       = "index.handler"
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda-code/s3m-lambda-authorizer.zip")
 }