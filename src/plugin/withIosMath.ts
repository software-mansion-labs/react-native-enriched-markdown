import configPlugins, { type ConfigPlugin } from '@expo/config-plugins';
import fs from 'fs';
import path from 'path';

const { withDangerousMod } = configPlugins;

const IOS_MATH_OPTION = "ENV['ENRICHED_MARKDOWN_ENABLE_MATH'] = '0'";

export const withIosMath: ConfigPlugin<{ enableMath?: boolean }> = (
  config,
  { enableMath = true }
) => {
  return withDangerousMod(config, [
    'ios',
    async (modConfig) => {
      const file = path.join(
        modConfig.modRequest.platformProjectRoot,
        'Podfile'
      );
      const contents = fs.readFileSync(file, 'utf8');

      const lines = contents.split('\n');
      const filteredLines = lines.filter(
        (line) => !line.includes('ENRICHED_MARKDOWN_ENABLE_MATH')
      );

      if (enableMath === false) {
        filteredLines.unshift(IOS_MATH_OPTION);
      }

      fs.writeFileSync(file, filteredLines.join('\n'));

      return modConfig;
    },
  ]);
};
