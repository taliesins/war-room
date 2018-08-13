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
var Consumer = kafka.Consumer;
var KeyedMessage = kafka.KeyedMessage;
var Client = kafka.Client;
var client = new Client(config.globalKafkaConnectionString);
var topic = config.topic;
var producer = new Producer(client, config.globalKafkaProducerSettings);

var consumer = new Consumer(
  client,
  [],
  {fromOffset: true}
);

var consumerMessagesProcessed = [];

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

app.get('/produce', async function (req, res) {
  var message = 'a message';
  var keyedMessage = new KeyedMessage('keyed', 'a keyed message');
  var payloads = [
    { topic: topic, partition: p, messages: [message, keyedMessage], attributes: a }
  ];

  const sendToTopic = (payloads) => new Promise((resolve, reject) => producer.send(payloads, function (err, result) {
    if (err) {
      return reject(err)
    }

    return resolve(result)
  }));

  await sendToTopic(payloads).then(result=> {
    console.error('Messages sent to topic');
    res.send('Messages sent to topic\n');
  }).catch(error => {
    console.error(error);
    next(err); // Pass errors to Express.
  });
});

app.get('/consumed', function (req, res) {
  res.send(consumerMessagesProcessed);
});

app.get('/hash/:id', function (req, res) {
  var hmac = crypto.createHmac('sha256', config.hashSalt+config.hashSecret);
  var hash = hmac.update(req.params.id);
  var signature = hash.digest('base64');
  res.send(signature);
});

producer.on('ready', function () {
  console.log('Producer is ready');
});    

producer.on('error', function (err) {
  console.log('error', err);
});

consumer.on('message', function (message) {
  consumerMessagesProcessed+=message;
  console.log("received message", message);
});

// Ensure we subscribed to message event before we start consuming from topic
consumer.addTopics([
  { topic: topic, partition: 0, offset: 0}
], () => console.log("Consumer is subscribed to topic"));

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
  const producerClose = (messages) => new Promise((resolve, reject) => producer.close(function (err) {
    if (err) {
      return reject(err)
    }

    return resolve()
  }));

  const serverClose = (messages) => new Promise((resolve, reject) => server.close(function (err) {
    if (err) {
      return reject(err)
    }

    return resolve()
  }));

  await producerClose().catch(error => {
    console.error(error);
    process.exitCode = 1;
  });

  await serverClose().catch(error => {
    console.error(error);
    process.exitCode = 1;
  });

  process.exit();
}
//
// need above in docker container to properly exit
//

module.exports = app;
