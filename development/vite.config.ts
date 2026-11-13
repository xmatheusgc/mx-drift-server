import { defineConfig } from 'vite';
export default defineConfig({ root: 'development/ui', base: './', build: { target: 'chrome103', outDir: '../../resources/[mx]/mx-freeroam-menu/dist', emptyOutDir: true }, server: { host: '127.0.0.1' } });
