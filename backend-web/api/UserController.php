<?php
/**
 * User API Controller
 * TND System - PHP Native Version
 */

require_once __DIR__ . '/../classes/User.php';
require_once __DIR__ . '/../utils/Auth.php';
require_once __DIR__ . '/../utils/Response.php';

class UserController {
    
    /**
     * Get all users
     */
    public static function index($request) {
        Auth::requireAdmin();
        
        $userModel = new User();
        $users = $userModel->findAll('name ASC');
        
        // Remove passwords from response
        foreach ($users as &$user) {
            unset($user['password']);
        }
        
        Response::success($users);
    }
    
    /**
     * Get user by ID
     */
    public static function show($request, $id) {
        Auth::require();
        
        // Users can only view their own profile unless they're admin
        if (Auth::id() != $id && !Auth::isAdmin()) {
            Response::forbidden();
        }
        
        $userModel = new User();
        $user = $userModel->findById($id);
        
        if (!$user) {
            Response::notFound('User not found');
        }
        
        unset($user['password']);
        Response::success($user);
    }
    
    /**
     * Create new user
     */
    public static function store($request) {
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
     * Update user
     */
    public static function update($request, $id) {
        Auth::require();
        
        // Users can only update their own profile unless they're admin
        if (Auth::id() != $id && !Auth::isAdmin()) {
            Response::forbidden();
        }
        
        $userModel = new User();
        $user = $userModel->findById($id);
        
        if (!$user) {
            Response::notFound('User not found');
        }
        
        $validation = $request->validate([
            'name' => 'required|min:2',
            'email' => 'required|email'
        ]);
        
        if ($validation !== true) {
            Response::validationError($validation);
        }
        
        // Check if email already exists for another user
        $existingUser = $userModel->findByEmail($request->get('email'));
        if ($existingUser && $existingUser['id'] != $id) {
            Response::error('Email already exists', 400);
        }
        
        $userData = [
            'name' => $request->get('name'),
            'email' => $request->get('email'),
            'phone' => $request->get('phone')
        ];
        
        // Only admin can update role
        if (Auth::isAdmin() && $request->has('role')) {
            $userData['role'] = $request->get('role');
        }
        
        // Only admin can update is_active
        if (Auth::isAdmin() && $request->has('is_active')) {
            $userData['is_active'] = $request->get('is_active');
        }
        
        $success = $userModel->updateUser($id, $userData);
        
        if ($success) {
            $updatedUser = $userModel->findById($id);
            unset($updatedUser['password']);
            Response::success($updatedUser, 'User updated successfully');
        } else {
            Response::error('Failed to update user', 500);
        }
    }
    
    /**
     * Delete user
     */
    public static function delete($request, $id) {
        Auth::requireAdmin();
        
        // Prevent deleting own account
        if (Auth::id() == $id) {
            Response::error('Cannot delete your own account', 400);
        }
        
        $userModel = new User();
        $user = $userModel->findById($id);
        
        if (!$user) {
            Response::notFound('User not found');
        }
        
        $success = $userModel->delete($id);
        
        if ($success) {
            Response::success(null, 'User deleted successfully');
        } else {
            Response::error('Failed to delete user', 500);
        }
    }
    
    /**
     * Get users by role
     */
    public static function getByRole($request, $role) {
        Auth::requireAdmin();
        
        $userModel = new User();
        $users = $userModel->findByRole($role);
        
        // Remove passwords from response
        foreach ($users as &$user) {
            unset($user['password']);
        }
        
        Response::success($users);
    }
}