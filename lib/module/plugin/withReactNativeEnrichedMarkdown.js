"use strict";

import { withIosMath } from "./withIosMath.js";
import { withAndroidMath } from "./withAndroidMath.js";
const withEnrichedMarkdown = (config, props) => {
  const enableMath = props?.enableMath !== false;
  config = withAndroidMath(config, {
    enableMath
  });
  config = withIosMath(config, {
    enableMath
  });
  return config;
};
export default withEnrichedMarkdown;
//# sourceMappingURL=withReactNativeEnrichedMarkdown.js.map