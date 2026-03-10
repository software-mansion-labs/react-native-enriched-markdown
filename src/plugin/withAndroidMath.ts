import { type ConfigPlugin, withGradleProperties } from '@expo/config-plugins';

export const withAndroidMath: ConfigPlugin<{ enableMath?: boolean }> = (
  config,
  { enableMath = true }
) => {
  return withGradleProperties(config, (gradleConfig) => {
    gradleConfig.modResults = gradleConfig.modResults.filter(
      (prop: any) => prop.key !== 'enrichedMarkdown.enableMath'
    );

    if (enableMath === false) {
      gradleConfig.modResults.push({
        type: 'property',
        key: 'enrichedMarkdown.enableMath',
        value: 'false',
      });
    }

    return gradleConfig;
  });
};
