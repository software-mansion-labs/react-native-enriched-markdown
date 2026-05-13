/** @type{import("@storybook/react-webpack5").StorybookConfig} */
module.exports = {
  stories: ['../components/**/*.stories.?(ts|tsx|js|jsx)'],
  addons: ['@storybook/addon-docs'],
  framework: {
    name: '@storybook/react-native-web-vite',
    options: {},
  },
  docs: {
    autodocs: true,
  },

  typescript: {
    reactDocgen: 'react-docgen',
  },
};
