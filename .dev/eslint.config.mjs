// eslint.config.js
import { defineConfig } from 'eslint/config'

export default defineConfig([
  {
    ignores: ['node_modules/**', 'dist/**'],
    rules: {
      'prefer-const': 'error',
      'no-unused-vars': ['error', { varsIgnorePattern: '^_' }],
    },
  },
])
