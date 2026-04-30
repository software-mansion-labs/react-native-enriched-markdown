import { NavigationContainer } from '@react-navigation/native';
import { Stack } from './navigation/Stack';
import HomeScreen from './screens/HomeScreen';
import PlaygroundScreen from './screens/PlaygroundScreen';
import TextScreen from './screens/TextScreen';
import InputScreen from './screens/InputScreen';
import StreamingMarkdownSimulator from './screens/StreamingMarkdownSimulator';

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Home"
        screenOptions={{
          headerStyle: {
            backgroundColor: '#007AFF',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{ title: 'Enriched Markdown Examples' }}
        />
        <Stack.Screen
          name="Playground"
          component={PlaygroundScreen}
          options={{ title: 'Playground' }}
        />
        <Stack.Screen
          name="Text"
          component={TextScreen}
          options={{ title: 'Text' }}
        />
        <Stack.Screen
          name="Input"
          component={InputScreen}
          options={{ title: 'Input' }}
        />
        <Stack.Screen
          name="Stream"
          component={StreamingMarkdownSimulator}
          options={{ title: 'Stream' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
