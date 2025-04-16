import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://ec2-13-127-72-180.ap-south-1.compute.amazonaws.com:3000', // Your EC2 instance
        changeOrigin: true,
        secure: false
      }
    }
  }
});