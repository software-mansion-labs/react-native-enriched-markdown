import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import type { RootStackScreenProps } from '../navigation/types';

type Props = RootStackScreenProps<'Home'>;

export default function HomeScreen({ navigation }: Props) {
  return (
    <View style={styles.container} testID="home-screen">
      <Text style={styles.title}>Enriched Markdown Examples</Text>
      <Text style={styles.subtitle}>
        Explore different markdown rendering and input capabilities
      </Text>

      <TouchableOpacity
        style={[styles.button, styles.playgroundButton]}
        onPress={() => navigation.navigate('Playground')}
        testID="home-block-playground"
      >
        <Text style={styles.buttonText}>Playground</Text>
        <Text style={styles.buttonSubtext}>live editor with preview</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.textButton]}
        onPress={() => navigation.navigate('Text')}
        testID="home-block-text"
      >
        <Text style={styles.buttonText}>Text</Text>
        <Text style={styles.buttonSubtext}>static markdown rendering</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.inputButton]}
        onPress={() => navigation.navigate('Input')}
        testID="home-block-input"
      >
        <Text style={styles.buttonText}>Input</Text>
        <Text style={styles.buttonSubtext}>chat-style rich text input</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.streamButton]}
        onPress={() => navigation.navigate('Stream')}
        testID="home-block-stream"
      >
        <Text style={styles.buttonText}>Stream</Text>
        <Text style={styles.buttonSubtext}>streaming markdown with tables</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 10,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 40,
    textAlign: 'center',
  },
  button: {
    paddingHorizontal: 30,
    paddingVertical: 15,
    borderRadius: 10,
    marginVertical: 10,
    minWidth: 250,
  },
  playgroundButton: {
    backgroundColor: '#007AFF',
  },
  textButton: {
    backgroundColor: '#34C759',
  },
  inputButton: {
    backgroundColor: '#FF9500',
  },
  streamButton: {
    backgroundColor: '#AF52DE',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  buttonSubtext: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 2,
  },
});
