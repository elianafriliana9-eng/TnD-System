<?php
/**
 * Request Utility Class
 * TND System - PHP Native Version
 */

class Request {
    private $method;
    private $uri;
    private $headers;
    private $body;
    private $queryParams;
    
    public function __construct() {
        $this->method = $_SERVER['REQUEST_METHOD'];
        $this->uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        $this->headers = getallheaders() ?: [];
        $this->queryParams = $_GET;
        
        // Strip the base path '/backend-web/api' from the URI
        $basePath = '/backend-web/api';
        if (strpos($this->uri, $basePath) === 0) {
            $this->uri = substr($this->uri, strlen($basePath));
        }
        error_log("Request URI after stripping base path: " . $this->uri);

        // Get request body
        $input = file_get_contents('php://input');
        $this->body = json_decode($input, true) ?: [];
        
        // Merge POST data if available
        if (!empty($_POST)) {
            $this->body = array_merge($this->body, $_POST);
        }
    }
    
    public function getMethod() {
        return $this->method;
    }
    
    public function getUri() {
        return $this->uri;
    }
    
    public function getHeaders() {
        return $this->headers;
    }
    
    public function getHeader($name) {
        return $this->headers[$name] ?? null;
    }
    
    public function getBody() {
        return $this->body;
    }
    
    public function get($key = null, $default = null) {
        if ($key === null) {
            return $this->body;
        }
        return $this->body[$key] ?? $default;
    }
    
    public function getQuery($key = null, $default = null) {
        if ($key === null) {
            return $this->queryParams;
        }
        return $this->queryParams[$key] ?? $default;
    }
    
    public function has($key) {
        return isset($this->body[$key]);
    }
    
    public function hasQuery($key) {
        return isset($this->queryParams[$key]);
    }
    
    public function validate($rules) {
        $errors = [];
        
        foreach ($rules as $field => $rule) {
            $ruleArray = is_array($rule) ? $rule : explode('|', $rule);
            $value = $this->get($field);
            
            foreach ($ruleArray as $singleRule) {
                if ($singleRule === 'required' && empty($value)) {
                    $errors[$field][] = "{$field} is required";
                }
                
                if (strpos($singleRule, 'min:') === 0 && !empty($value)) {
                    $min = (int) substr($singleRule, 4);
                    if (strlen($value) < $min) {
                        $errors[$field][] = "{$field} must be at least {$min} characters";
                    }
                }
                
                if (strpos($singleRule, 'max:') === 0 && !empty($value)) {
                    $max = (int) substr($singleRule, 4);
                    if (strlen($value) > $max) {
                        $errors[$field][] = "{$field} must not exceed {$max} characters";
                    }
                }
                
                if ($singleRule === 'email' && !empty($value)) {
                    if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                        $errors[$field][] = "{$field} must be a valid email address";
                    }
                }
                
                if ($singleRule === 'numeric' && !empty($value)) {
                    if (!is_numeric($value)) {
                        $errors[$field][] = "{$field} must be numeric";
                    }
                }
            }
        }
        
        return empty($errors) ? true : $errors;
    }
    
    public function getBearerToken() {
        $authHeader = $this->getHeader('Authorization');
        if ($authHeader && strpos($authHeader, 'Bearer ') === 0) {
            return substr($authHeader, 7);
        }
        return null;
    }
}