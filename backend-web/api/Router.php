<?php
/**
 * API Router
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/Request.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Auth.php';

class Router {
    private $routes = [];
    private $request;
    
    public function __construct() {
        $this->request = new Request();
    }
    
    public function get($path, $handler) {
        $this->addRoute('GET', $path, $handler);
    }
    
    public function post($path, $handler) {
        $this->addRoute('POST', $path, $handler);
    }
    
    public function put($path, $handler) {
        $this->addRoute('PUT', $path, $handler);
    }
    
    public function delete($path, $handler) {
        $this->addRoute('DELETE', $path, $handler);
    }
    
    private function addRoute($method, $path, $handler) {
        $this->routes[] = [
            'method' => $method,
            'path' => $path,
            'handler' => $handler
        ];
    }
    
    public function dispatch() {
        $method = $this->request->getMethod();
        $uri = $this->request->getUri();
        
        error_log("Dispatching request: Method = $method, URI = $uri");

        // Handle OPTIONS request for CORS
        if ($method === 'OPTIONS') {
            Response::json(['message' => 'OK'], 200);
        }
        
        foreach ($this->routes as $route) {
            if ($route['method'] === $method) {
                $pattern = $this->pathToRegex($route['path']);
                error_log("Attempting to match route: Path = {$route['path']}, Pattern = $pattern against URI = $uri");
                if (preg_match($pattern, $uri, $matches)) {
                    error_log("Route matched: {$route['path']}");
                    // Extract parameters
                    $params = array_slice($matches, 1);
                    
                    try {
                        call_user_func_array($route['handler'], array_merge([$this->request], $params));
                        return;
                    } catch (Exception $e) {
                        Response::error('Internal server error: ' . $e->getMessage(), 500);
                    }
                }
            }
        }
        
        Response::notFound('Endpoint not found');
    }
    
    private function pathToRegex($path) {
        // Convert path parameters like {id} to regex capture groups
        $pattern = preg_replace('/\{([^}]+)\}/', '([^/]+)', $path);
        return '#^' . $pattern . '$#';
    }
}