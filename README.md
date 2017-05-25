# kong-plugin-deviceuid
A Kong plugin that will add a sticky deviceuid cookie to all requests

## How it works

When enabled, this plugin will add a new "deviceuid" cookie to all request and it will persist the value across request
making this user traceable across requests.

## Install

Install luarocks and run the following command

```
luarocks install kong-plugin-deviceuid
```

## Configuration

Configuring the plugin is straightforward, you can add it on top of an API by executing the following request on your Kong server:

```bash
curl -X POST http://localhost:8001/apis/{api_id}/plugins \
--data "name=deviceuid" \
--data "config.cookie_name=deviceuid"
```
form parameter|required|description
---|---|---
`name`|*required*|The name of the plugin to use, in this case: `deviceuid`
`cookie_name`|*optional*|The name of the cookie you want to use