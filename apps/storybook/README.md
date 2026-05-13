# Storybook

Storybook app for `react-native-enriched-markdown`, built with [React Native](https://reactnative.dev).

## Getting Started

> **Note**: Make sure you have completed the [Set Up Your Environment](https://reactnative.dev/docs/set-up-your-environment) guide before proceeding.

## Step 1: Start Metro

From the repository root:

```sh
yarn storybook start
```

## Step 2: Build and run the app

With Metro running, open a new terminal and run:

### Android

```sh
yarn storybook android
```

### iOS

```sh
yarn storybook ios
```

## Troubleshooting

If you see the default React Native screen instead of Storybook, make sure Metro was started with `yarn storybook start` and not `react-native start` directly — the `STORYBOOK_ENABLED=true` env var must be set when Metro starts.
