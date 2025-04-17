import js from '@eslint/js'
import globals from 'globals'
import react from 'eslint-plugin-react'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tsParser from '@typescript-eslint/parser'
import tsPlugin from '@typescript-eslint/eslint-plugin'
import securityPlugin from 'eslint-plugin-security'
import sonarjsPlugin from 'eslint-plugin-sonarjs'

export default [
  { 
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/.next/**',
      '**/coverage/**'
    ]
  },
  {
    files: ['src/**/*.{js,jsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
      parserOptions: {
        ecmaVersion: 'latest',
        ecmaFeatures: { jsx: true },
        sourceType: 'module',
      },
    },
    settings: { react: { version: '18.3' } },
    plugins: {
      react,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...js.configs.recommended.rules,
      ...react.configs.recommended.rules,
      ...react.configs['jsx-runtime'].rules,
      ...reactHooks.configs.recommended.rules,
      'react/jsx-no-target-blank': 'off',
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],
    },
  },
  {
    files: ['src/**/*.{js,jsx,ts,tsx}'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 2021,
        sourceType: 'module',
        ecmaFeatures: {
          jsx: true
        }
      }
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      'security': securityPlugin,
      'sonarjs': sonarjsPlugin
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      ...securityPlugin.configs.recommended.rules,
      ...sonarjsPlugin.configs.recommended.rules,
      'security/detect-object-injection': 'warn',
      'security/detect-non-literal-require': 'warn',
      'security/detect-non-literal-fs-filename': 'warn',
      'security/detect-eval-with-expression': 'warn',
      'security/detect-unsafe-regex': 'warn',
      'security/detect-pseudoRandomBytes': 'warn',
      'sonarjs/no-duplicate-string': 'warn',
      'sonarjs/no-identical-functions': 'warn',
      'sonarjs/no-small-switch': 'warn',
      'sonarjs/no-unused-collection': 'warn',
      'sonarjs/prefer-immediate-return': 'warn',
      'sonarjs/prefer-object-literal': 'warn',
      'sonarjs/no-collapsible-if': 'warn',
      'sonarjs/no-redundant-boolean': 'warn',
      'sonarjs/no-redundant-jump': 'warn',
      'sonarjs/no-useless-catch': 'warn',
      'sonarjs/prefer-single-boolean-return': 'warn',
      'sonarjs/no-nested-assignment': 'warn',
      'sonarjs/block-scoped-var': 'warn',
      'sonarjs/cognitive-complexity': ['warn', 20],
      'sonarjs/no-nested-conditional': 'warn',
      'sonarjs/no-ignored-exceptions': 'warn',
      'sonarjs/no-use-of-empty-return-value': 'warn'
    }
  }
]
