"use strict";

import configPlugins from '@expo/config-plugins';
const {
  withGradleProperties
} = configPlugins;
export const withAndroidMath = (config, {
  enableMath = true
}) => {
  if (enableMath) {
    return config;
  }
  return withGradleProperties(config, gradleConfig => {
    gradleConfig.modResults = gradleConfig.modResults.filter(prop => prop.type !== 'property' || prop.key !== 'enrichedMarkdown.enableMath');
    gradleConfig.modResults.push({
      type: 'property',
      key: 'enrichedMarkdown.enableMath',
      value: 'false'
    });
    return gradleConfig;
  });
};
//# sourceMappingURL=withAndroidMath.js.map