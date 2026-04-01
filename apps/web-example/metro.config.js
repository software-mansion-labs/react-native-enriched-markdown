const { getDefaultConfig } = require('expo/metro-config');

const path = require('path');

const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, '../..');

const pkg = require('../../package.json');

const config = getDefaultConfig(projectRoot);

// Watch the monorepo root so Metro picks up changes to the library source.
config.watchFolders = [monorepoRoot];

// Resolve node_modules from both the project and the monorepo root.
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(monorepoRoot, 'node_modules'),
];

// Redirect the library's package name to its source entry point so that
// Metro doesn't try to load the built output (./lib/module/index.js) which
// is not committed to the repo. Use the platform-specific entry on web.
const upstreamResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (moduleName === pkg.name) {
    const entry = platform === 'web' ? 'src/index.web.tsx' : 'src/index.tsx';
    return {
      filePath: path.resolve(monorepoRoot, entry),
      type: 'sourceFile',
    };
  }
  if (upstreamResolveRequest) {
    return upstreamResolveRequest(context, moduleName, platform);
  }
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = config;
