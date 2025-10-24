// eslint.config.js
import { defineConfig } from 'eslint/config'

export default defineConfig([
  {
    rules: {
      'prefer-const': 'error',
      'no-unused-vars': ['error', { varsIgnorePattern: '^_' }],
    },
  },
])
