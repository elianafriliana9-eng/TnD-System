// Authentication management for admin panel
let currentUser = null;
let sessionTimeout = null;
let activityTimeout = null;
const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes in milliseconds
const ACTIVITY_CHECK_INTERVAL = 60 * 1000; // Check every 1 minute

// Prevent infinite redirect loop
let authCheckInProgress = false;

document.addEventListener('DOMContentLoaded', function() {
    console.log('🔍 DOM loaded, checking auth status...');
    
    // Only check auth if we're NOT on login page
    if (!window.location.pathname.includes('login.html')) {
        checkAuthStatus();
    }
});

async function checkAuthStatus() {
    // Prevent multiple simultaneous auth checks
    if (authCheckInProgress) {
        console.log('⏸️ Auth check already in progress, skipping...');
        return;
    }
    
    authCheckInProgress = true;
    console.log('🔑 Checking authentication status...');
    
    try {
        // Check if user data exists in localStorage
        const userData = localStorage.getItem('userData');
        if (!userData) {
            console.log('❌ No user data in localStorage, redirecting to login...');
            redirectToLogin();
            authCheckInProgress = false;
            return;
        }
        
        // Check session timeout
        if (isSessionExpired()) {
            console.log('⏰ Session expired, redirecting to login...');
            await handleSessionExpired();
            authCheckInProgress = false;
            return;
        }
        
        // Verify with API
        const response = await AuthAPI.me();
        console.log('🔑 Auth response:', response);
        
        if (response.success) {
            currentUser = response.data;
            updateUserInfo();
            updateLastActivity();
            startSessionMonitoring();
            console.log('✅ User authenticated, showing dashboard...');
            showDashboard(); // Show default page
        } else {
            console.log('❌ User not authenticated, redirecting to login...');
            redirectToLogin();
        }
    } catch (error) {
        console.error('❌ Auth check failed:', error);
        redirectToLogin();
    } finally {
        authCheckInProgress = false;
    }
}

// Session timeout management
function updateLastActivity() {
    const now = new Date().getTime();
    localStorage.setItem('lastActivity', now.toString());
    console.log('⏱️ Activity updated:', new Date(now).toLocaleTimeString());
}

function getLastActivity() {
    const lastActivity = localStorage.getItem('lastActivity');
    return lastActivity ? parseInt(lastActivity) : new Date().getTime();
}

function isSessionExpired() {
    const lastActivity = getLastActivity();
    const now = new Date().getTime();
    const timeSinceLastActivity = now - lastActivity;
    return timeSinceLastActivity > SESSION_TIMEOUT;
}

function startSessionMonitoring() {
    // Clear any existing timers
    if (sessionTimeout) clearTimeout(sessionTimeout);
    if (activityTimeout) clearInterval(activityTimeout);
    
    // Track user activity
    const activityEvents = ['mousedown', 'keypress', 'scroll', 'touchstart', 'click'];
    activityEvents.forEach(event => {
        document.addEventListener(event, updateLastActivity, { passive: true });
    });
    
    // Check for inactivity every minute
    activityTimeout = setInterval(() => {
        if (isSessionExpired()) {
            console.log('⏰ Session timeout detected, logging out...');
            handleSessionExpired();
        } else {
            const timeSinceActivity = new Date().getTime() - getLastActivity();
            const remainingTime = SESSION_TIMEOUT - timeSinceActivity;
            const remainingMinutes = Math.floor(remainingTime / 60000);
            
            console.log('⏱️ Session active, remaining time:', remainingMinutes, 'minutes');
            
            // Update session indicator
            updateSessionIndicator();
            
            // Show warning 5 minutes before timeout
            if (remainingMinutes === 5) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Session Expiring Soon',
                    text: 'Your session will expire in 5 minutes due to inactivity. Please move your mouse or click something to stay logged in.',
                    toast: true,
                    position: 'top-end',
                    showConfirmButton: false,
                    timer: 5000,
                    timerProgressBar: true
                });
            }
        }
    }, ACTIVITY_CHECK_INTERVAL);
}

async function handleSessionExpired() {
    // Clear monitoring
    if (sessionTimeout) clearTimeout(sessionTimeout);
    if (activityTimeout) clearInterval(activityTimeout);
    
    // Clear user data
    localStorage.removeItem('userData');
    localStorage.removeItem('lastActivity');
    
    // Show timeout message
    await Swal.fire({
        icon: 'warning',
        title: 'Session Expired',
        text: 'Your session has expired due to inactivity. Please login again.',
        confirmButtonText: 'OK',
        allowOutsideClick: false
    });
    
    redirectToLogin();
}

function updateUserInfo() {
    const userNameElement = document.getElementById('user-name');
    if (userNameElement && currentUser) {
        userNameElement.textContent = currentUser.name;
    }
    
    updateSessionIndicator();
}

function updateSessionIndicator() {
    const indicator = document.getElementById('sessionIndicator');
    if (!indicator) return;
    
    const timeSinceActivity = new Date().getTime() - getLastActivity();
    const remainingTime = SESSION_TIMEOUT - timeSinceActivity;
    const remainingMinutes = Math.floor(remainingTime / 60000);
    
    if (remainingMinutes <= 5) {
        // Warning state - less than 5 minutes
        indicator.style.background = '#fef3c7';
        indicator.innerHTML = '<i class="fas fa-circle text-warning" style="font-size: 10px;"></i>';
        indicator.title = `Session expires in ${remainingMinutes} minute(s)`;
    } else if (remainingMinutes <= 10) {
        // Caution state - less than 10 minutes
        indicator.style.background = '#fef9c3';
        indicator.innerHTML = '<i class="fas fa-circle text-warning" style="font-size: 10px;"></i>';
        indicator.title = `Session expires in ${remainingMinutes} minute(s)`;
    } else {
        // Active state
        indicator.style.background = '#f0fdf4';
        indicator.innerHTML = '<i class="fas fa-circle text-success" style="font-size: 10px;"></i>';
        indicator.title = 'Session Active';
    }
}

function redirectToLogin() {
    // Prevent redirect loop - only redirect if not already on login page
    if (!window.location.pathname.includes('login.html')) {
        console.log('🔄 Redirecting to login page...');
        window.location.href = 'login.html';
    }
}

async function logout() {
    try {
        const result = await Swal.fire({
            title: 'Are you sure?',
            text: 'You will be logged out from the system',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, logout!'
        });

        if (result.isConfirmed) {
            // Clear session monitoring
            if (sessionTimeout) clearTimeout(sessionTimeout);
            if (activityTimeout) clearInterval(activityTimeout);
            
            // Clear all user data
            localStorage.removeItem('userData');
            localStorage.removeItem('lastActivity');
            localStorage.removeItem('user');
            
            try {
                await AuthAPI.logout();
            } catch (e) {
                console.log('Logout API call failed, but continuing with local logout');
            }
            
            Swal.fire({
                icon: 'success',
                title: 'Logged out!',
                text: 'You have been successfully logged out',
                timer: 2000,
                showConfirmButton: false
            }).then(() => {
                redirectToLogin();
            });
        }
    } catch (error) {
        console.error('Logout failed:', error);
        // Force cleanup and redirect even if API call fails
        localStorage.clear();
        redirectToLogin();
    }
}

function showProfile() {
    if (!currentUser) return;
    
    const modalHTML = `
        <div class="modal fade" id="profileModal" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-user me-2"></i>User Profile
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <form id="profileForm">
                            <div class="form-floating mb-3">
                                <input type="text" class="form-control" id="profileName" value="${currentUser.name}" required>
                                <label for="profileName">Full Name</label>
                            </div>
                            <div class="form-floating mb-3">
                                <input type="email" class="form-control" id="profileEmail" value="${currentUser.email}" required>
                                <label for="profileEmail">Email</label>
                            </div>
                            <div class="form-floating mb-3">
                                <input type="text" class="form-control" id="profilePhone" value="${currentUser.phone || ''}" placeholder="Phone">
                                <label for="profilePhone">Phone</label>
                            </div>
                            <div class="form-floating mb-3">
                                <select class="form-select" id="profileRole" disabled>
                                    <option value="super_admin" ${currentUser.role === 'super_admin' ? 'selected' : ''}>Super Admin</option>
                                    <option value="admin" ${currentUser.role === 'admin' ? 'selected' : ''}>Admin</option>
                                    <option value="supervisor" ${currentUser.role === 'supervisor' ? 'selected' : ''}>Supervisor</option>
                                    <option value="auditor" ${currentUser.role === 'auditor' ? 'selected' : ''}>Auditor</option>
                                </select>
                                <label for="profileRole">Role</label>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-primary" onclick="updateProfile()">Update Profile</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('modal-container').innerHTML = modalHTML;
    const modal = new bootstrap.Modal(document.getElementById('profileModal'));
    modal.show();
}

async function updateProfile() {
    const name = document.getElementById('profileName').value;
    const email = document.getElementById('profileEmail').value;
    const phone = document.getElementById('profilePhone').value;
    
    try {
        const response = await UsersAPI.update(currentUser.id, {
            name: name,
            email: email,
            phone: phone
        });
        
        if (response.success) {
            currentUser = response.data;
            updateUserInfo();
            
            const modal = bootstrap.Modal.getInstance(document.getElementById('profileModal'));
            modal.hide();
            
            showSuccess('Profile updated successfully');
        }
    } catch (error) {
        showErrorAlert(error.message || 'Failed to update profile');
    }
}

function showChangePassword() {
    const modalHTML = `
        <div class="modal fade" id="changePasswordModal" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-key me-2"></i>Change Password
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <form id="changePasswordForm">
                            <div class="form-floating mb-3">
                                <input type="password" class="form-control" id="currentPassword" required>
                                <label for="currentPassword">Current Password</label>
                            </div>
                            <div class="form-floating mb-3">
                                <input type="password" class="form-control" id="newPassword" required minlength="6">
                                <label for="newPassword">New Password</label>
                            </div>
                            <div class="form-floating mb-3">
                                <input type="password" class="form-control" id="confirmPassword" required minlength="6">
                                <label for="confirmPassword">Confirm New Password</label>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-primary" onclick="changePassword()">Change Password</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('modal-container').innerHTML = modalHTML;
    const modal = new bootstrap.Modal(document.getElementById('changePasswordModal'));
    modal.show();
}

async function changePassword() {
    const currentPassword = document.getElementById('currentPassword').value;
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    
    if (newPassword !== confirmPassword) {
        showErrorAlert('New password confirmation does not match');
        return;
    }
    
    try {
        const response = await AuthAPI.changePassword(currentPassword, newPassword, confirmPassword);
        
        if (response.success) {
            const modal = bootstrap.Modal.getInstance(document.getElementById('changePasswordModal'));
            modal.hide();
            
            showSuccess('Password changed successfully');
        }
    } catch (error) {
        showErrorAlert(error.message || 'Failed to change password');
    }
}