import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

// Define the middleware plugin
/** @type {import('vite').Plugin} */
const logRequestMiddleware = {
	name: 'log-request-middleware',
	configureServer(server) {
		server.middlewares.use((req, res, next) => {
			res.setHeader('Access-Control-Allow-Origin', '*');
			res.setHeader('Access-Control-Allow-Methods', 'GET');
			res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
			res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
			next();
		});
	}
};

export default defineConfig({
	plugins: [sveltekit()],
	define: {
		APP_VERSION: JSON.stringify(process.env.npm_package_version),
		APP_BUILD_HASH: JSON.stringify(process.env.APP_BUILD_HASH || 'dev-build')
	},
	build: {
		sourcemap: true
	},
	worker: {
		format: 'es'
	},
	// Add development specific settings
	server: {
		hmr: {
			overlay: true
		},
		// Add proxy if needed for your backend
		proxy: {
			'/api': {
				target: 'http://localhost:8080',
				changeOrigin: true
			},
			'/static': {  // Proxy the static folder
				target: 'http://localhost:8080',
				changeOrigin: true
			},
			'/uploads': {  // Proxy the uploads folder
				target: 'http://localhost:8080',
				changeOrigin: true
			},
			'/assets': {  // Proxy the assets folder
				target: 'http://localhost:8080',
				changeOrigin: true
			},
			'manifest.json': {  // Proxy the manifest.json file
				target: 'http://localhost:8080/static/manifest.json',
				changeOrigin: true
			},
		},
		// Optimize hot reload
		watch: {
			usePolling: false,
			ignored: ['**/node_modules/**', '**/dist/**']
		}
	},
	optimizeDeps: {
		exclude: ['pyodide'] // Prevent Vite from trying to optimize Pyodide
	}
});