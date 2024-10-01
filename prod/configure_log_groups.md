
https://www.alexdebrie.com/posts/api-gateway-access-logs/

{"requestTime":"$context.requestTime", "request_id" : "$context.requestId",  "httpMethod":"$context.httpMethod",  "path": "$context.path",  "resourcePath":"$context.resourcePath",  "status":"$context.status",  "integrationRequestId": "$context.integration.requestId",  "functionResponseStatus": "$context.integration.status",  "integrationLatency": "$context.integration.latency",  "integrationServiceStatus": "$context.integration.integrationStatus",  "authorizeResultStatus": "$context.authorize.status",  "authorizerServiceStatus": "$context.authorizer.status",  "authorizerLatency": "$context.authorizer.latency",  "authorizerRequestId": "$context.authorizer.requestId", "authorizeResultStatus": "$context.authorizer.status",  "authorizerRequestId": "$context.authorizer.requestId",  "ip": "$context.identity.sourceIp",  "protocol":"$context.protocol", "userAgent": "$context.identity.userAgent",  "principalId": "$context.authorizer.principalId",  "cognitoUser": "$context.identity.cognitoIdentityId",  "user": "$context.identity.user",  "apiId" : "$context.apiId",  "accountId" : "$context.identity.accountId"}




{
    "requestTime":"$context.requestTime",  
    "request_id" : "$context.requestId",
    "httpMethod":"$context.httpMethod",
    "path": "$context.path",
    "resourcePath":"$context.resourcePath",
    "status":"$context.status",
    "integrationRequestId": "$context.integration.requestId",
    "functionResponseStatus": "$context.integration.status",
    "integrationLatency": "$context.integration.latency",
    "integrationServiceStatus": "$context.integration.integrationStatus",
    "authorizeResultStatus": "$context.authorize.status",
    "authorizerServiceStatus": "$context.authorizer.status",
    "authorizerLatency": "$context.authorizer.latency",
    "authorizerRequestId": "$context.authorizer.requestId",   
    "authorizeResultStatus": "$context.authorizer.status",
    "authorizerRequestId": "$context.authorizer.requestId",
    "ip": "$context.identity.sourceIp",
    "protocol":"$context.protocol",   
    "userAgent": "$context.identity.userAgent",
    "principalId": "$context.authorizer.principalId",
    "cognitoUser": "$context.identity.cognitoIdentityId",
    "user": "$context.identity.user",
    "apiId" : "$context.apiId",
    "accountId" : "$context.identity.accountId",
}