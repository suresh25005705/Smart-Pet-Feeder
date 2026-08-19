import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;

  final String broker =
      'e57b208c333749f9b9816d9fa9c6f79d.s1.eu.hivemq.cloud';

  final int port = 8883;

  final String topic =
      'smartpetfeeder/feeder01/command';

  Future<bool> connect() async {
    // Short client ID
    final clientId =
    'flutter_feeder_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient(broker, clientId);

    // Secure MQTT
    client.secure = true;
    client.port = 8883;

    // IMPORTANT:
    // Use MQTT 3.1.1 instead of the default MQTT 3.1
    client.setProtocolV311();

	  client.connectTimeoutPeriod = 15000;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.autoReconnect = false;

    client.onConnected = () {
      print('==============================');
      print('MQTT CONNECTED SUCCESSFULLY');
      print('==============================');
    };

    client.onDisconnected = () {
      print('==============================');
      print('MQTT DISCONNECTED');
      print('==============================');
    };

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(
          'test',
          'qwerty123',
        )
        .startClean();

    client.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      print('Broker: $broker');
      print('Port: $port');
      print('Protocol: MQTT 3.1.1');
      print('Client ID: $clientId');

      await client.connect();
    } catch (e) {
      print('MQTT CONNECTION ERROR: $e');

      client.disconnect();

      return false;
    }

    if (client.connectionStatus?.state ==
    MqttConnectionState.connected) {

  print('MQTT connection state: CONNECTED');

  // Subscribe
  client.subscribe(
    topic,
    MqttQos.atLeastOnce,
  );

  print('MQTT SUBSCRIBED TO: $topic');

  // Receive messages
  client.updates?.listen(
    (List<MqttReceivedMessage<MqttMessage>> messages) {

      for (final message in messages) {

        final receivedMessage =
            message.payload as MqttPublishMessage;

        final payload =
            MqttPublishPayload.bytesToStringAsString(
          receivedMessage.payload.message,
        );

        print('==============================');
        print('MQTT MESSAGE RECEIVED');
        print('Topic: ${message.topic}');
        print('Message: $payload');
        print('==============================');
      }
    },
  );

  return true;
}

    print(
      'MQTT connection state: '
      '${client.connectionStatus?.state}',
    );

    print(
      'MQTT return code: '
      '${client.connectionStatus?.returnCode}',
    );

    return false;
  }

  void publishFeedCommand() {
    if (client.connectionStatus?.state !=
        MqttConnectionState.connected) {
      print('Cannot publish: MQTT is not connected.');
      return;
    }

    final builder = MqttClientPayloadBuilder();

    builder.addString('FEED');

    client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    print('==============================');
    print('MQTT MESSAGE SENT: FEED');
    print('Topic: $topic');
    print('==============================');
  }

  void disconnect() {
    if (client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      client.disconnect();
    }
  }
}
