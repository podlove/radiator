var tailwindcss = require('tailwindcss');

module.exports = {
  plugins: [
    require('precss'),
    tailwindcss('./tailwind.js'),
    require('autoprefixer')
  ]
}
