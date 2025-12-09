// API Configuration and Helper Functions
// Configured for Production Server with HTTPS
// Frontend at root, Backend at /backend-web/
const API_BASE_URL = 'https://tndsystem.online/backend-web/api';

// Get base path for frontend
function getBasePath() {
    // Frontend is at root level now
    return '';
}

// Check if current page is login page
function isLoginPage() {
    return window.location.pathname.includes('login.html');
}

// Get login page URL
function getLoginURL() {
    return getBasePath() + '/login.html';
}

class API {
    static baseURL = 'https://tndsystem.online/backend-web';
    
    static async request(endpoint, options = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        console.log('API Request URL:', url); // Debug log
        
        // Get token from localStorage
        const token = localStorage.getItem('user_token');
        
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            },
            credentials: 'include', // Include cookies for session management
        };

        const config = { ...defaultOptions, ...options };

        try {
            const response = await fetch(url, config);
            console.log('API Response status:', response.status); // Debug log
            
            let data;
            try {
                data = await response.json();
            } catch (parseError) {
                console.error('JSON Parse Error:', parseError);
                throw new Error('Invalid JSON response from server');
            }

            console.log('API Response data:', data); // Debug log

            // Handle authentication errors
            if (response.status === 401) {
                // Redirect to login if not authenticated
                if (!isLoginPage()) {
                    console.log('Authentication required, redirecting to login...');
                    window.location.href = getLoginURL();
                }
                throw new Error('Authentication required');
            }

            if (!response.ok) {
                throw new Error(data.message || 'API request failed');
            }

            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    }

    static async get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }

    static async post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    static async put(endpoint, data) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    }

    static async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }
}

// Authentication API
class AuthAPI {
    static async login(email, password) {
        return API.post('/login-session.php', { email, password });
    }

    static async logout() {
        return API.post('/logout.php', {});
    }

    static async me() {
        return API.get('/me.php');
    }

    static async changePassword(currentPassword, newPassword, confirmPassword) {
        return API.post('/auth/change-password', {
            current_password: currentPassword,
            new_password: newPassword,
            confirm_password: confirmPassword
        });
    }
}

// Users API
class UsersAPI {
    static async getAll() {
        return API.get('/users-simple.php');
    }

    static async getById(id) {
        return API.get(`/user-detail.php?id=${id}`);
    }

    static async create(userData) {
        return API.post('/users-create.php', userData);
    }

    static async update(id, userData) {
        userData.id = id; // Add ID to data for POST request
        return API.post('/user-update.php', userData);
    }

    static async delete(id) {
        return API.post('/user-delete.php', { id: id });
    }

    static async changePassword(userId, newPassword) {
        return API.post('/user-change-password.php', { 
            user_id: userId, 
            new_password: newPassword 
        });
    }

    static async getByRole(role) {
        return API.get(`/users.php?role=${role}`);
    }
}

// Utility functions
function showLoading() {
    return `
        <div class="loading">
            <i class="fas fa-spinner fa-spin"></i>
            <p class="mt-3">Loading...</p>
        </div>
    `;
}

function showError(message) {
    return `
        <div class="alert alert-danger" role="alert">
            <i class="fas fa-exclamation-triangle me-2"></i>
            ${message}
        </div>
    `;
}

function showSuccess(message) {
    Swal.fire({
        icon: 'success',
        title: 'Success!',
        text: message,
        timer: 3000,
        showConfirmButton: false
    });
}

function showErrorAlert(message) {
    Swal.fire({
        icon: 'error',
        title: 'Error!',
        text: message
    });
}

function confirmDelete(message = 'Are you sure you want to delete this item?') {
    return Swal.fire({
        title: 'Are you sure?',
        text: message,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#3085d6',
        confirmButtonText: 'Yes, delete it!'
    });
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Format currency
function formatCurrency(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR'
    }).format(amount);
}

// Get badge class for status
function getStatusBadge(status) {
    const badges = {
        'active': 'bg-success',
        'inactive': 'bg-secondary',
        'pending': 'bg-warning',
        'completed': 'bg-success',
        'cancelled': 'bg-danger',
        'in_progress': 'bg-info'
    };
    return badges[status] || 'bg-secondary';
}