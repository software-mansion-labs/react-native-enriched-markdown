const path = require('path');
const {getDefaultConfig} = require('@react-native/metro-config');
const withStorybook = require('@storybook/react-native/metro/withStorybook');
const {withMetroConfig} = require('react-native-monorepo-config');

const root = path.resolve(__dirname, '../..');
const defaultConfig = getDefaultConfig(__dirname);

module.exports = withStorybook(
  withMetroConfig(defaultConfig, {root, dirname: __dirname}),
  {
    enabled: process.env.STORYBOOK_ENABLED === 'true',
    onDisabledRemoveStorybook: true,
  },
);
