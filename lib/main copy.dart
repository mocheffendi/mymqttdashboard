import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MQTT Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MQTTTestPage(),
    );
  }
}

class MQTTTestPage extends StatefulWidget {
  const MQTTTestPage({super.key});

  @override
  State<MQTTTestPage> createState() => _MQTTTestPageState();
}

class _MQTTTestPageState extends State<MQTTTestPage> {
  final client = MqttBrowserClient(
      'wss://e30ec8cdf6ef4746b68cb97c21d1faff.s1.eu.hivemq.cloud:8884/mqtt',
      '');

  final String server =
      'e30ec8cdf6ef4746b68cb97c21d1faff.s1.eu.hivemq.cloud'; // Replace with your MQTT server
  // final int port = 8883; // Default TLS port
  final String clientId = 'flutter_client'; // Client ID
  final String username = 'mocheffendi'; // Optional
  final String password = 'EVANorma1984'; // Optional

  // late MqttServerClient client;
  bool isConnected = false;
  String receivedMessage = '';

  @override
  void initState() {
    super.initState();
    // client = MqttServerClient.withPort(server, clientId, port);
    // client.secure = true; // Use TLS
    // client.logging(on: true);
    // client.setProtocolV311();
    // client.connectionMessage = MqttConnectMessage()
    //     .withClientIdentifier(clientId)
    //     .startClean()
    //     .authenticateAs(username, password);
    client.logging(on: false);

    /// Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    /// The connection timeout period can be set if needed, the default is 5 seconds.
    client.connectTimeoutPeriod = 2000; // milliseconds

    /// The ws port for Mosquitto is 8080, for wss it is 8081
    client.port = 8884;

    /// Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    /// Add the successful connection callback
    client.onConnected = onConnected;

    /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
    /// You can add these before connection or change them dynamically after connection if
    /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
    /// can fail either because you have tried to subscribe to an invalid topic or the broker
    /// rejects the subscribe request.
    client.onSubscribed = onSubscribed;

    /// Set a ping received callback if needed, called whenever a ping response(pong) is received
    /// from the broker.
    client.pongCallback = pong;

    /// Set the appropriate websocket headers for your connection/broker.
    /// Mosquito uses the single default header, other brokers may be fine with the
    /// default headers.
    client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;

    /// Create a connection message to use or use the default one. The default one sets the
    /// client identifier, any supplied username/password and clean session,
    /// an example of a specific one below.
    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean()
        .authenticateAs(
            username, password) // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);

    // print('EXAMPLE::Hive client connecting....');
    client.connectionMessage = connMess;
  }

  Future<void> connectMQTT() async {
    try {
      await client.connect();
    } on Exception catch (e) {
      // print('EXAMPLE::client exception - $e');
      client.disconnect();
      // return -1;
    }
    // try {
    //   print('Connecting to MQTT...');
    //   await client.connect();
    //   if (client.connectionStatus!.state == MqttConnectionState.connected) {
    //     print('Connected to MQTT');
    //     setState(() {
    //       isConnected = true;
    //     });
    //   } else {
    //     print('Connection failed: ${client.connectionStatus}');
    //   }
    // } catch (e) {
    //   print('Error: $e');
    //   client.disconnect();
    // }
  }

  void subscribeToTopic(String topic) {
    if (isConnected) {
      client.subscribe(topic, MqttQos.atLeastOnce);
      client.updates!
          .listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        final message = messages![0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        // print('Received message: $payload from topic: ${messages[0].topic}');
        setState(() {
          receivedMessage = payload;
        });
      });
    }
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    // print(builder);
    // if (isConnected) {
    //   final builder = MqttClientPayloadBuilder();
    //   builder.addString(message);
    //   client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    //   print('Published: $message to $topic');
    // }
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    // print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    // print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    // if (client.connectionStatus!.disconnectionOrigin ==
    //     MqttDisconnectionOrigin.solicited) {
    //   print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    // }
    // print('Disconnected from broker');
    setState(() {
      isConnected = false;
    });
  }

  /// The successful connect callback
  void onConnected() {
    // print(
    // 'EXAMPLE::OnConnected client callback - Client connection was sucessful');
    // print('Connected to broker');
    setState(() {
      isConnected = true;
    });

    // Subscribe to a topic
    const topic = 'example/topic'; // Replace with your topic
    client.subscribe(topic, MqttQos.atLeastOnce);

    // Listen for messages
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      // print('Received message: $payload from topic: ${c[0].topic}');
      setState(() {
        receivedMessage = payload;
      });
    });
  }

  /// Pong callback
  void pong() {
    // print('EXAMPLE::Ping response client callback invoked');
  }

  @override
  Widget build(BuildContext context) {
    final topicController = TextEditingController();
    final messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'MQTT Status: ${isConnected ? "Connected" : "Disconnected"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (for publishing)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => subscribeToTopic(topicController.text),
              child: const Text('Subscribe'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () =>
                  publishMessage(topicController.text, messageController.text),
              child: const Text('Publish'),
            ),
            const SizedBox(height: 20),
            if (receivedMessage.isNotEmpty)
              Text(
                'Received Message: $receivedMessage',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: connectMQTT,
        tooltip: 'Connect to MQTT Server',
        child: const Icon(Icons.power),
      ),
    );
  }
}
