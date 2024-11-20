import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_button_screen.dart';
import 'mqtt_service.dart';

class MQTTDashboard extends StatefulWidget {
  const MQTTDashboard({super.key});

  @override
  State<MQTTDashboard> createState() => _MQTTDashboardState();
}

class _MQTTDashboardState extends State<MQTTDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // A map to hold the dynamic state of each button
  final Map<String, String> _buttonStates = {};

  @override
  void initState() {
    super.initState();

    // Create a map to associate topics with button IDs
    Map<String, String> topicToButtonIdMap = {};

    // Connect to MQTT
    MQTTService()
        .connect(
            'wss://e30ec8cdf6ef4746b68cb97c21d1faff.s1.eu.hivemq.cloud:8884/mqtt',
            'mocheffendi',
            'EVANorma1984')
        .then((_) {
      if (MQTTService().isConnected) {
        // Fetch button data from Firestore
        _firestore.collection('buttons').get().then((snapshot) {
          for (var doc in snapshot.docs) {
            final button = doc.data();
            final subscribeTopic = button['subscribeTopic'];
            final onValue = button['onValue'];
            final offValue = button['offValue'];

            // Map the topic to the button ID
            topicToButtonIdMap[subscribeTopic] = doc.id;

            // print(
            //     'Subscribing to topic: $subscribeTopic with ON: $onValue, OFF: $offValue');

            // Subscribe to the topic
            MQTTService().subscribe(subscribeTopic, (receivedTopic, payload) {
              // Check which button the topic corresponds to
              // final buttonId = topicToButtonIdMap[subscribeTopic];
              // Check if the message's topic matches the button's topic
              if (receivedTopic == subscribeTopic) {
                // print('Message received on topic $receivedTopic: $payload');
                if (payload == onValue) {
                  // print('Setting button ${doc.id} to ON');
                  setState(() {
                    _buttonStates[doc.id] = "ON";
                  });
                } else if (payload == offValue) {
                  // print('Setting button ${doc.id} to OFF');
                  setState(() {
                    _buttonStates[doc.id] = "OFF";
                  });
                }
              }
            });
          }
        });
      }
    });
  }

  void _toggleButton(String buttonId, Map<String, dynamic> buttonData) {
    final currentState = _buttonStates[buttonId];
    final newState =
        currentState == "ON" ? buttonData['offValue'] : buttonData['onValue'];

    // MQTTService().subscribe(buttonData['subscribeTopic'], (message));
    // Publish the new state to the MQTT broker
    MQTTService().publish(buttonData['publishTopic'], newState);
    // Update the local state for immediate feedback (MQTT will confirm)
    setState(() {
      _buttonStates[buttonId] =
          newState == buttonData['onValue'] ? "ON" : "OFF";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MQTT Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: _firestore.collection('buttons').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final buttons = snapshot.data!.docs;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                final buttonDoc = buttons[index];
                final buttonData = buttonDoc.data() as Map<String, dynamic>;
                final buttonState = _buttonStates[buttonDoc.id] ?? "OFF";

                return GestureDetector(
                  onLongPress: () => _editButton(buttonDoc.id, buttonData),
                  child: InkWell(
                    onTap: () => _toggleButton(buttonDoc.id, buttonData),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 4.0, top: 4.0, left: 4.0, right: 4.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        color: buttonState == 'ON' ? Colors.red : Colors.grey,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: buttonState == 'ON'
                                    ? Colors.yellow
                                    : Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(buttonData['name']),
                              Text(buttonDoc.id)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewButton,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editButton(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditButtonScreen(buttonId: id, buttonData: data),
      ),
    );
  }

  void _addNewButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditButtonScreen(),
      ),
    );
  }
}
