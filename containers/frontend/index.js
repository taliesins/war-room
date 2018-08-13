'use strict';
var config = require('config-node')();

// simple node web server that displays hello world
// optimized for Docker image

var express = require('express');
// this example uses express web framework so we know what longer build times
// do and how Dockerfile layer ordering matters. If you mess up Dockerfile ordering
// you'll see long build times on every code change + build. If done correctly,
// code changes should be only a few seconds to build locally due to build cache.

var morgan = require('morgan');
// morgan provides easy logging for express, and by default it logs to stdout
// which is a best practice in Docker. Friends don't let friends code their apps to
// do app logging to files in containers.

var crypto = require('crypto');

// Constants
const PORT = process.env.PORT || 8080;
// if you're not using docker-compose for local development, this will default to 8080
// to prevent non-root permission problems with 80. Dockerfile is set to make this 80
// because containers don't have that issue :)

// Kafka
var kafka = require('kafka-node');
var Producer = kafka.Producer;
var KeyedMessage = kafka.KeyedMessage;
var Client = kafka.Client;
var client = new Client(config.globalKafkaConnectionString);
var topic = config.topic;
var producer = new Producer(client, config.globalKafkaProducerSettings);

// App
var app = express();

app.use(morgan('common'));

app.get('/', function (req, res) {
  res.send('Hello Docker World\n');
});

app.get('/healthz', function (req, res) {
	// do app logic here to determine if app is truly healthy
	// you should return 200 if healthy, and anything else will fail
	// if you want, you should be able to restrict this to localhost (include ipv4 and ipv6)
  res.send('I am happy and healthy\n');
});

app.get('/produce', function (req, res) {
  var message = 'a message';
  var keyedMessage = new KeyedMessage('keyed', 'a keyed message');

  producer.send([
    { topic: topic, partition: p, messages: [message, keyedMessage], attributes: a }
  ], function (err, result) {
    console.log(err || result);
    process.exit();
  });  
  
  res.send('Hello Docker World\n');
});

app.get('/hash/:id', function (req, res) {
  var hash = crypto.createHmac('sha256', config.hashSalt+config.hashSecret).update(req.params.id).digest('base64');
  res.send(hash);
});

producer.on('ready', function () {
  console.log('Producer is ready');
});    

producer.on('error', function (err) {
  console.log('error', err);
});

var server = app.listen(PORT, function () {
  console.log('Webserver is ready');
});

//
// need this in docker container to properly exit since node doesn't handle SIGINT/SIGTERM
// this also won't work on using npm start since:
// https://github.com/npm/npm/issues/4603
// https://github.com/npm/npm/pull/10868
// https://github.com/RisingStack/kubernetes-graceful-shutdown-example/blob/master/src/index.js
// if you want to use npm then start with `docker run --init` to help, but I still don't think it's
// a graceful shutdown of node process
//

// quit on ctrl-c when running docker in terminal
process.on('SIGINT', async function onSigint () {
	console.info('Got SIGINT (aka ctrl-c in docker). Graceful shutdown ', new Date().toISOString());
  await shutdown();
});

// quit properly on docker stop
process.on('SIGTERM', async function onSigterm () {
  console.info('Got SIGTERM (docker container stop). Graceful shutdown ', new Date().toISOString());
  await shutdown();
})

// shut down server
async function shutdown() {
  const serverClose = () => new Promise(resolve => server.close(err => resolve(err)));
  const producerClose = () => new Promise(resolve => producer.close(err => resolve(err)));
  
  serverCloseErr = await serverClose()
  if (serverCloseErr) {
    console.error(serverCloseErr);
    process.exitCode = 1;
  } 

  producerCloseErr = await producerClose();
  if (producerCloseErr) {
    console.error(producerCloseErr);
    process.exitCode = 1;
  } 

  process.exit();
}
//
// need above in docker container to properly exit
//

module.exports = app;
