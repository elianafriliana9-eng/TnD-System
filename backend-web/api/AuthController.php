<?php
/**
 * Authentication API Endpoints
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/../classes/User.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Response.php';

class AuthController {
    
    /**
     * User login
     */
    public static function login($request) {
        $validation = $request->validate([
            'email' => 'required|email',
            'password' => 'required|min:6'
        ]);
        
        if ($validation !== true) {
            Response::validationError($validation);
        }
        
        $email = $request->get('email');
        $password = $request->get('password');
        
        $user = Auth::login($email, $password);
        
        if ($user) {
            Response::success($user, 'Login successful');
        } else {
            Response::error('Invalid credentials', 401);
        }
    }
    
    /**
     * User logout
     */
    public static function logout($request) {
        Auth::logout();
        Response::success(null, 'Logout successful');
    }
    
    /**
     * Get current user
     */
    public static function me($request) {
        Auth::require();
        $user = Auth::user();
        Response::success($user);
    }
    
    /**
     * User registration (admin only)
     */
    public static function register($request) {
        Auth::requireAdmin();
        
        $validation = $request->validate([
            'name' => 'required|min:2',
            'email' => 'required|email',
            'password' => 'required|min:6',
            'role' => 'required'
        ]);
        
        if ($validation !== true) {
            Response::validationError($validation);
        }
        
        $userModel = new User();
        
        // Check if email already exists
        $existingUser = $userModel->findByEmail($request->get('email'));
        if ($existingUser) {
            Response::error('Email already exists', 400);
        }
        
        $userData = [
            'name' => $request->get('name'),
            'email' => $request->get('email'),
            'password' => $request->get('password'),
            'role' => $request->get('role'),
            'phone' => $request->get('phone'),
            'is_active' => 1
        ];
        
        $userId = $userModel->createUser($userData);
        
        if ($userId) {
            $user = $userModel->findById($userId);
            unset($user['password']);
            Response::success($user, 'User created successfully', 201);
        } else {
            Response::error('Failed to create user', 500);
        }
    }
    
    /**
     * Change password
     */
    public static function changePassword($request) {
        Auth::require();
        
        $validation = $request->validate([
            'current_password' => 'required',
            'new_password' => 'required|min:6',
            'confirm_password' => 'required'
        ]);
        
        if ($validation !== true) {
            Response::validationError($validation);
        }
        
        if ($request->get('new_password') !== $request->get('confirm_password')) {
            Response::error('New password confirmation does not match', 400);
        }
        
        $userModel = new User();
        $currentUser = $userModel->findById(Auth::id());
        
        if (!password_verify($request->get('current_password'), $currentUser['password'])) {
            Response::error('Current password is incorrect', 400);
        }
        
        $success = $userModel->updatePassword(Auth::id(), $request->get('new_password'));
        
        if ($success) {
            Response::success(null, 'Password changed successfully');
        } else {
            Response::error('Failed to change password', 500);
        }
    }
}