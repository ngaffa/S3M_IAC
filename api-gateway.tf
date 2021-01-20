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
  rest_api_id = aws_api_gateway_rest_api.s3m-ag-proxy.id
  resource_id   = aws_api_gateway_resource.s3m-ag-resource.id
  http_method   = "ANY"
  authorization = "NONE"
  
}

resource "aws_api_gateway_integration" "s3m-ag-integration" {
  rest_api_id = aws_api_gateway_rest_api.s3m-ag-proxy.id
  resource_id = aws_api_gateway_resource.s3m-ag-resource.id
  http_method = aws_api_gateway_method.s3m-ag-method-any.http_method
  integration_http_method = "ANY"
  type        = "HTTP_PROXY"
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.s3m-vpc-link.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
  uri =format("http://", aws_lb.s3m-nlb.dns_name,"/{proxy}")
  
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
