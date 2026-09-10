// SVGO config for the achievement badge SVGs.
//
// flutter_svg (this project's version) does NOT apply CSS from internal
// <style> blocks, so class-based fills render as default black. This config
// inlines those styles into presentation attributes (fill="#..." etc.), the
// same format the app's avatar/banner SVGs use and which flutter_svg renders
// correctly. Gradients, clipPaths, stroke and opacity are preserved.
//
// Run via scripts/flatten-achievement-svgs.sh after any fresh designer export.
export default {
  multipass: true,
  plugins: [
    { name: 'inlineStyles', params: { onlyMatchedOnce: false, removeMatchedSelectors: true } },
    'convertStyleToAttrs',
  ],
};
