resource "aws_api_gateway_rest_api" "s3m-ag-proxy" {
  name        = "s3m-ag-proxy"
  description = "This is my the proxy API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "s3m-ag-resource" {
  rest_api_id = aws_api_gateway_rest_api.s3m-ag-proxy.id
  parent_id   = aws_api_gateway_rest_api.s3m-ag-proxy.root_resource_id
  path_part   = "{proxy+}"


}

resource "aws_api_gateway_method" "s3m-ag-method-any" {
  rest_api_id   = aws_api_gateway_rest_api.s3m-ag-proxy.id
  resource_id   = aws_api_gateway_resource.s3m-ag-resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.s3m-ag-authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "s3m-ag-integration" {
  rest_api_id             = aws_api_gateway_rest_api.s3m-ag-proxy.id
  resource_id             = aws_api_gateway_resource.s3m-ag-resource.id
  http_method             = aws_api_gateway_method.s3m-ag-method-any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.s3m-vpc-link.id
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  # /{proxy} is required when using authorizer
  uri = join("/", ["http:/", aws_lb.s3m-nlb.dns_name, "{proxy}"])
  

}

resource "aws_api_gateway_deployment" "s3m-sg-stage-dev" {
  depends_on = [
    aws_api_gateway_integration.s3m-ag-integration
  ]
  rest_api_id = aws_api_gateway_rest_api.s3m-ag-proxy.id
  stage_name  = "dev"
}


resource "aws_api_gateway_vpc_link" "s3m-vpc-link" {
  name        = "s3m-vpc-link"
  description = "example description"
  target_arns = [aws_lb.s3m-nlb.arn]
}


#Enable corse

resource "aws_api_gateway_method" "s3m-ag-method-option" {
    rest_api_id   = aws_api_gateway_rest_api.s3m-ag-proxy.id
    resource_id   = aws_api_gateway_resource.s3m-ag-resource.id
    http_method   = "OPTIONS"
    authorization = "NONE"
}
resource "aws_api_gateway_method_response" "s3m-ag-method-options_200" {
    rest_api_id   = aws_api_gateway_rest_api.s3m-ag-proxy.id
    resource_id   = aws_api_gateway_resource.s3m-ag-resource.id
    http_method   = aws_api_gateway_method.s3m-ag-method-option.http_method
    status_code   = "200"
    response_models = {
      "application/json" = "Empty"
    }
    
   response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = ["aws_api_gateway_method.s3m-ag-method-option"]
}
resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = aws_api_gateway_rest_api.s3m-ag-proxy.id
    resource_id   = aws_api_gateway_resource.s3m-ag-resource.id
    http_method   = aws_api_gateway_method.s3m-ag-method-option.http_method
    type          = "MOCK"
    depends_on = [aws_api_gateway_method.s3m-ag-method-option]
}
resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.s3m-ag-proxy.id
    resource_id   = aws_api_gateway_resource.s3m-ag-resource.id
    http_method   = aws_api_gateway_method.s3m-ag-method-option.http_method
    status_code   = aws_api_gateway_method_response.s3m-ag-method-options_200.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
    depends_on = [aws_api_gateway_method_response.s3m-ag-method-options_200]
}
