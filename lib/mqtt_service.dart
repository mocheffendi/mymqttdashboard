import 'dart:async';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:developer';
// import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  late MqttBrowserClient _client;

  bool isConnected = false;

  factory MQTTService() {
    return _instance;
  }

  MQTTService._internal() {
    // const String username = 'mocheffendi'; // Optional
    // const String password = 'EVANorma1984'; // Optional

    // _client = MqttBrowserClient(
    //     'wss://e30ec8cdf6ef4746b68cb97c21d1faff.s1.eu.hivemq.cloud:8884/mqtt',
    //     '');

    // _client.port = 8884;
    // _client.keepAlivePeriod = 60;
    // _client.onConnected = _onConnected;
    // _client.onDisconnected = _onDisconnected;
    // _client.onSubscribed = _onSubscribed;
    // _client.onUnsubscribed = _onUnsubscribed;
    // _client.onSubscribeFail = _onSubscribeFail;
    // _client.logging(on: false);
    // _client.setProtocolV311();
    // _client.keepAlivePeriod = 20;
    // _client.connectTimeoutPeriod = 2000; // milliseconds
    // _client.onDisconnected = onDisconnected;
    // _client.autoReconnect = true;
    // _client.onConnected = onConnected;
    // _client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    // final connMess = MqttConnectMessage()
    //     .withClientIdentifier(clientId)
    //     .withWillTopic(
    //         'willtopic') // If you set this you must set a will message
    //     .withWillMessage('My Will message')
    //     .startClean()
    //     .authenticateAs(
    //         username, password) // Non persistent session for testing
    //     .withWillQos(MqttQos.atLeastOnce);

    // print('EXAMPLE::Hive client connecting....');
    // _client.connectionMessage = connMess;
    // _client.connect();
    // connect();
  }

  // Connect to the MQTT broker
  Future<void> connect(String server, String username, String password) async {
    const String clientId = 'flutter_client'; // Client ID
    _client = MqttBrowserClient(server, '');
    _client.port = 8884;
    _client.keepAlivePeriod = 60;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.onUnsubscribed = _onUnsubscribed;
    _client.onSubscribeFail = _onSubscribeFail;
    _client.logging(on: false);
    _client.setProtocolV311();
    // _client.keepAlivePeriod = 20;
    _client.connectTimeoutPeriod = 2000; // milliseconds
    // _client.onDisconnected = onDisconnected;
    // _client.autoReconnect = true;
    // _client.onConnected = onConnected;
    _client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean()
        .authenticateAs(
            username, password) // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);

    // print('EXAMPLE::Hive client connecting....');
    _client.connectionMessage = connMess;
    // _client.connect();
    // connect();
    try {
      _client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(_client.clientIdentifier)
          .withWillTopic('will/topic') // Will topic
          .withWillMessage('Client disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      // print('Connecting to the MQTT broker...');
      await _client.connect(username, password);
    } catch (e) {
      // print('Error connecting to MQTT broker: $e');
      disconnect();
    }
  }

  // Disconnect from the MQTT broker
  void disconnect() {
    _client.disconnect();
  }

  // Publish a message
  void publish(String topic, String message) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      // print('Published: $message to topic: $topic');
    } else {
      // print('Cannot publish. MQTT client is not connected.');
    }
  }

  void subscribe(
      String topic, Function(String topic, String message) callback) {
    if (isConnected) {
      _client.subscribe(topic, MqttQos.atLeastOnce);
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttReceivedMessage<MqttMessage> receivedMessage = c[0];
        final String receivedTopic = receivedMessage.topic;

        // Extract payload from the message
        final MqttPublishMessage publishMessage =
            receivedMessage.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            publishMessage.payload.message);

        // Pass the topic and payload to the callback
        callback(receivedTopic, payload);
        // print('Message received on topic $receivedTopic: $payload');
      });
    } else {
      // print('Cannot subscribe. MQTT client is not connected.');
    }
  }

  // Callback for when the client connects
  void _onConnected() {
    log('MQTT client connected.');
    isConnected = true;
  }

  // Callback for when the client disconnects
  void _onDisconnected() {
    log('MQTT client disconnected.');
    isConnected = false;
  }

  // Callback for when a topic is successfully subscribed to
  void _onSubscribed(String topic) {
    log('MQTT client is subscribed to topic: $topic');
  }

  // Callback for when subscription fails
  void _onSubscribeFail(String topic) {
    log('MQTT client is failed subscribe to topic: $topic');
  }

  // Callback for when a topic is unsubscribed
  void _onUnsubscribed(String? topic) {
    log('MQTT client unsubscribed from topic: $topic');
  }
}
