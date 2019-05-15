var tailwindcss = require('tailwindcss');

module.exports = {
  plugins: [
    // require('precss'),
    tailwindcss('./tailwind.config.js'),
    require('autoprefixer')
  ]
}
