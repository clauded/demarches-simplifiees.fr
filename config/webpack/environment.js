const path = require('path');
const { environment } = require('@rails/webpacker');

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.splitChunks();
environment.config.merge({ resolve });
<<<<<<< HEAD
=======

const nodeModulesLoader = environment.loaders.get('nodeModules');
if (!Array.isArray(nodeModulesLoader.exclude)) {
  nodeModulesLoader.exclude =
    nodeModulesLoader.exclude == null ? [] : [nodeModulesLoader.exclude];
}
nodeModulesLoader.exclude.push(/mapbox-gl/);
>>>>>>> 4c19e9324... fixup! migrate map to mapbox-gl with a react component

// Uncoment next lines to run webpack-bundle-analyzer
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
// environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());

module.exports = environment;
