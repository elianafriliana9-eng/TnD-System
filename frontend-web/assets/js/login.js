// Login functionality
document.addEventListener('DOMContentLoaded', function() {
    // Check if already logged in
    checkAuthStatus();
    
    const loginForm = document.getElementById('loginForm');
    loginForm.addEventListener('submit', handleLogin);
    
    // Toggle password visibility
    const togglePassword = document.getElementById('togglePassword');
    const passwordInput = document.getElementById('password');
    const eyeIcon = document.getElementById('eyeIcon');
    
    if (togglePassword) {
        togglePassword.addEventListener('click', function() {
            const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
            passwordInput.setAttribute('type', type);
            
            // Toggle eye icon
            if (type === 'text') {
                eyeIcon.classList.remove('fa-eye');
                eyeIcon.classList.add('fa-eye-slash');
                togglePassword.style.color = '#667eea';
            } else {
                eyeIcon.classList.remove('fa-eye-slash');
                eyeIcon.classList.add('fa-eye');
                togglePassword.style.color = '#94a3b8';
            }
        });
    }
    
    // Auto-focus email input
    document.getElementById('email').focus();
});

async function handleLogin(e) {
    e.preventDefault();
    
    const loginBtn = document.getElementById('loginBtn');
    const btnText = loginBtn.querySelector('span:first-of-type');
    const btnSpinner = loginBtn.querySelector('.spinner-border');
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    // Disable button and show loading
    loginBtn.disabled = true;
    btnText.textContent = 'Signing in...';
    btnSpinner.classList.remove('d-none');
    
    try {
        const response = await AuthAPI.login(email, password);
        
        if (response.success) {
            // Store user info (optional)
            localStorage.setItem('user', JSON.stringify(response.data));
            
            // Update button to success state
            btnText.textContent = 'Success!';
            btnSpinner.classList.add('d-none');
            loginBtn.innerHTML = '<i class="fas fa-check-circle me-2"></i>Success! Redirecting...';
            
            // Show success message with modern style
            await Swal.fire({
                icon: 'success',
                title: 'Welcome Back!',
                text: `Hello, ${response.data.name}`,
                timer: 1500,
                showConfirmButton: false,
                backdrop: true,
                allowOutsideClick: false,
                customClass: {
                    popup: 'animated fadeInDown'
                }
            });
            
            // Smooth redirect to admin panel
            window.location.href = 'index.html';
        }
    } catch (error) {
        // Reset button state
        btnText.textContent = 'Sign In to Dashboard';
        btnSpinner.classList.add('d-none');
        loginBtn.disabled = false;
        
        // Show error message with modern style
        Swal.fire({
            icon: 'error',
            title: 'Login Failed',
            text: error.message || 'Invalid email or password. Please try again.',
            confirmButtonText: 'Try Again',
            confirmButtonColor: '#667eea',
            customClass: {
                popup: 'animated shake'
            }
        });
    }
}

async function checkAuthStatus() {
    try {
        const response = await AuthAPI.me();
        if (response.success) {
            // User is already logged in, redirect to admin panel
            window.location.href = 'index.html';
        }
    } catch (error) {
        // User is not logged in, stay on login page
        console.log('User not authenticated');
    }
}