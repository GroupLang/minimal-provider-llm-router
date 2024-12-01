# Minimal provider setup

This repository is a minimal provider setup for [Market Router](https://api.marketrouter.ai). It contains the necessary code to deploy an API that will serve as a provider in Market Router.

You can use it as a base to enhance the functionalities of the provider, improve bidding strategies, etc.

The current functionalities are the following:
- Bid strategy: It scans for open instances and creates a proposal with the minimum bid allowed ($0.01).

- API Authentication: the API that will be used for proposals in the market gets authenticated with a static API key. We encourage future providers to enhance this system. For instance, implementing proposal-based API keys could offer more granular control.

- Completions endpoint: OpenAI-compatible wrapper with the model provided in the configuration file.

## Installation

1. **Clone the repository**

   ```shell
   git clone https://github.com/GroupLang/minimal-provider-llm-router.git
   cd minimal-provider-llm-router
   ```
2. **Install required libraries**
   ```shell
   python3.11 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
3. **Set up environment space**

### Why HTTPX is used instead of Requests

HTTPX is used in this project instead of the traditional `requests` library because it provides several advantages, particularly for asynchronous programming. HTTPX supports both synchronous and asynchronous requests, making it more versatile for modern Python applications that require non-blocking I/O operations. This is especially useful in scenarios where multiple requests need to be handled concurrently, improving the overall efficiency and performance of the application.

    - **Set up environment variables**

        Copy the sample environment file and configure it as per your requirements (see more [here](#setting-up-configuration-variables)).

        ```shell
        [ ! -f .env ] && cp .env.template .env
        ```

    - **Install pre-commit**

        Install the pre-commit hooks to ensure that your commits meet the project's standard for code quality and formatting. This will set up hooks that run checks such as linting and formatting before you commit your changes, helping to catch errors early and maintain consistent code style throughout the project.

        ```shell
        pre-commit install
        ```

## Market API key set up

### Registration
```shell
curl -X 'POST' \
  'https://api.marketrouter.ai/v1/auth/register' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "email": "user@example.com",
  "username": "string",
  "fullname": "string",
  "password": "string"
}'
```

### Login
After receiving a **HTTP 201** status code, you can proceed to login:

```shell
curl -X 'POST' \
  'https://api.marketrouter.ai/v1/auth/login' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=<USERNAME_HERE>&password=<PASSWORD_HERE>'
```

### API key creation
With the token received in the response `{"access_token":<TOKEN_HERE>, "token_type":"bearer"}`, you can create an API KEY to access the Market:

```shell
curl -X 'POST' \
  'https://api.marketrouter.ai/v1/auth/create-api-key?name=<API_KEY_NAME>&is_live=true' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <TOKEN_HERE>'
```

A successful response (with **HTTP 201** status code) looks like this:
```shell
{
    "api_key":<YOUR_API_KEY>,
    "name":<API_KEY_NAME>,
    "is_live":true
}
```

### Account top up

In order to be a provider, you need to ensure that your balance is positive. Otherwise, proposals won't be able to be created. To top up your account, call this endpoint:

```shell
curl -X 'POST' \
  'https://api.marketrouter.ai/v1/payment/deposit' \
  -H 'accept: application/json' \
  -H 'X-API-KEY: <YOUR_API_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
  "amount": 10,
  "description": "Deposit/Withdraw to account"
}'
```

If successful, you will receive a Stripe link to deposit money into your **account**.

## Setting up configuration variables
In order to run the project you should fill the `.env` with the following variables:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `NOTDIAMOND_API_KEY`

- `APP_COMPLETIONS_ENDPOINT`: the endpoint that requesters will use. It will have the following form: `http://example.provider/v1/completions/`. In the [cloud deployment](#cloud-deployment-aws) section, section we will explain how this variable can be set with a custom value.

## Running the API locally

In order to test the API locally, you can build the Docker image and run the API with the following commands:

```shell
docker build -t test . --no-cache
docker run -p 80:80 --env-file .env test
```

## Cloud deployment (AWS)
The `infrastructure/` directory contains all the necessary Terraform files to deploy the API in AWS.

The first step is to get the AWS credentials and store them in `$HOME/.aws`. Then, if it's the first time deploying the API, you need to create the secrets in AWS Secret Manager: 
```shell
bash create_secrets.sh
```

Next, you can deploy the API with the following command:
```shell
bash deploy.sh
```

Do note that if you want to re-deploy the API you don't need to create the secrets again. You can just execute `./deploy.sh`.

### Setting the App completions endpoint with a custom domain
As seen in the [Setting up configuration variables](#setting-up-configuration-variables) section, `APP_COMPLETIONS_ENDPOINT` is a necessary environment variable. It is the endpoint that will be provided to the Market when creating a proposal. If the proposal is the winning one, the Market will call this endpoint.

Having a static endpoint is important to ensure that deployments do not affect the minimal provider behavior. To get a static endpoint one needs to obtain the DNS name from the Application Load Balancer. Since this is created once the app is deployed, the first deployment should not submit proposals as they will not be able to fulfill until the requests to the given endpoint are redirected to the API.

Having said that, one needs to add the DNS name record to the domain managed in its domain-name registrar of choice. Doing this will complete the setup of the DNS name and the minimal provider app will have a static completions endpoint. Make sure to test the completions endpoint before submitting proposals.

Lastly, do not forget to update the secret `APP_COMPLETIONS_ENDPOINT` in AWS Secrets Manager and redeploy the API.
Temporary change to force divergence
